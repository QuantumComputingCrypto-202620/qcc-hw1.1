# Tarea: desbordamiento de buffer e inyeccion de shellcode

## Objetivo

Explotar un programa vulnerable compilado para tomar el control de su ejecucion,
inyectar shellcode en la pila y leer el archivo `flag.txt` del servidor.

El servidor se encuentra en:

```
nc 32.199.164.87 1337
```

La entrega consiste en completar la linea del `payload` en `exploit.py`.

hagale debug en una maquina linux al programa vulnShellCode

---

## 1. El programa vulnerable

```c
void vuln()
{
    puts("Ingrese un string, y este sera impreso de vuelta:");
    char buf[32];
    gets(buf);        // <-- lee sin verificar el tamano de buf
    puts(buf);
    fflush(stdout);
}
```

`gets()` copia lo que el usuario envie dentro de `buf`, que solo tiene 32 bytes,
pero no verifica cuanto se escribe. Al enviar mas de 32 bytes, la escritura
continua mas alla del buffer, sobre la pila, hasta alcanzar la **direccion de
retorno** de la funcion. Esa direccion es la que la CPU utiliza para saber a
donde volver cuando `vuln()` termina. Al sobrescribirla, se controla el registro
EIP y, con ello, el punto al que salta el programa.

El binario no tiene la seguridad tradicional que le pone el compilador como canarios, posicionamiento aleatorio en memoria etc, por lo cual es trivial atacarlo (note que incluso si están todas las protecciones, si el código tiene un error así, se pueden evadir las protecciones y hacer un ataque exitoso, pero no es tan trivial. El código debe ser seguro, los controles complementarios siempre tienden a fallar.)

### 1.1 Comandos clave de gdb y linux

Cuando descargue vuln para analizarlo, inicie su debug el linux con:

`gdb vulnShellCode`
y use estos comandos según necesite:

- **`disas /r funcion` (o `disassemble`):** Desensambla una función específica, mostrando el código en lenguaje ensamblador en lugar de C. El modificador `/r` (raw) es crucial en explotación porque imprime los bytes en crudo (opcodes o lenguaje máquina) en formato hexadecimal junto a cada instrucción. Esto permite a los estudiantes ver exactamente cómo se traducen las instrucciones y buscar secuencias de bytes (como `ff f4`).
- **`x/32xw $esp -16` (Examine):** Inspecciona el contenido directo de la memoria. La sintaxis se desglosa así:
- `x`: Comando base (examinar).
- `32`: Cantidad de bloques a mostrar.
- `x`: Formato de salida (hexadecimal).
- `w`: Tamaño del bloque (Word, que en x86 son 4 bytes).
- `$esp -16`: Dirección base de inicio (el puntero de la pila menos 16 bytes).
  Es ideal para visualizar un mapa amplio de la pila y verificar visualmente si el _padding_ (las "A"s) o el _shellcode_ aterrizaron en la ubicación esperada.

- **`b * 0x080490ab` (o `break`):** Establece un punto de interrupción en una dirección de memoria exacta. El uso del asterisco (`*`) es obligatorio cuando se indica una dirección de memoria en lugar del nombre de una función en el código fuente. Esto pausará la ejecución un instante antes de que el procesador ejecute la instrucción alojada en esa dirección (muy útil para detenerse justo antes de ejecutar un gadget de ROP).
- **`info regs` (o `info registers`):** Muestra el estado y los valores actuales de todos los registros del procesador (EAX, EBX, ESP, EIP, etc.) en el momento en que el programa está pausado. Permite confirmar si el atacante logró controlar algún registro o calcular distancias analizando a dónde apuntan los punteros de la pila o base.
- **`ni` (o `nexti`):** Avanza la ejecución del programa exactamente **una instrucción en ensamblador**, pero saltando por encima (step over) de las llamadas a funciones. Si la instrucción es un `call`, GDB ejecutará la función entera en segundo plano y se detendrá en la instrucción inmediatamente posterior al retorno. Es vital para depurar paso a paso sin quedar atrapado dentro del código interno de librerías inmensas como `libc`.
- **`run < <(printf 'A%.0s' {1..44}; printf '\x97\x90\x04\x08')`:** Inicia la ejecución del binario inyectando un _payload_ dinámico directamente desde la terminal, sin necesidad de escribir un script en Python ni crear archivos externos. Utiliza redirección de procesos de Bash:
- `printf 'A%.0s' {1..44}`: Imprime 44 veces el carácter "A" para llenar el _buffer_ y alcanzar el _offset_ exacto.
- `printf '\x97\x90\x04\x08'`: Concatena la dirección de memoria deseada formateada en _Little Endian_ para sobrescribir el registro EIP.

- **`c` (o `continue`):** Reanuda la ejecución continua del programa desde el punto donde estaba pausado. El programa seguirá corriendo hasta que finalice de manera natural, sufra un error grave (como un fallo de segmentación por un _exploit_ fallido), o alcance el siguiente _breakpoint_.

---

## 2. Anatomia del payload

El payload tendra tres partes, en este orden:

```
[  relleno  ][ direccion de retorno ][      shellcode      ]
```

### 2.1 El relleno (offset)

Es necesario determinar cuantos bytes hay desde el inicio de `buf` hasta la
direccion de retorno. A ese numero se le denomina el **offset**. No debe
adivinarse: debe medirse.

Con pwntools se emplea un patron ciclico, en el que cada
subcadena de 4 bytes es unica:

### 2.2 Que es un gadget y por que se necesita

Podria pensarse en una solucion directa: colocar el shellcode en la pila y
retornar a su direccion. El inconveniente es que siempre **ASLR esta activo** en el
servidor, por lo que la direccion de la pila cambia en cada ejecucion. No es
posible escribir un valor fijo de la pila en el payload, porque se desconoce cual
sera.

La solucion clasica es la tecnica **ret2reg**. En el instante en que `vuln()`
retorna, el registro ESP apunta justo despues de la direccion de retorno, es
decir, al inicio de la region donde se ubico el shellcode. En consecuencia, si en
lugar de saltar a un valor de la pila se salta a una instruccion que ordene
"saltar a donde apunta ESP", se alcanza el shellcode sin importar donde se
encuentre la pila.

Esa instruccion, tomada del propio binario, es un **gadget**: una secuencia corta
de bytes que ya existe en el codigo y que devuelve el control (por ejemplo,
mediante `ret`). Dado que el binario es `-no-pie`, su codigo reside en
direcciones fijas, de modo que la direccion del gadget si es un valor constante
que puede escribirse en el payload. Alli esta el mecanismo: el gadget reside en
la zona fija del binario y la pila reside en la zona aleatoria; se usa el primero
para alcanzar la segunda.

El gadget ideal seria un `jmp esp`. Sin embargo, este binario no contiene uno
limpio, por lo que debe buscarse un equivalente.

### 2.3 El gadget de este reto: `ff f4 8b 1c 24 c3`

Al analizar el binario aparece una secuencia de bytes que funciona como salto a
la pila. Desensamblada byte por byte:

| Bytes      | Instruccion      | Efecto                                      |
| ---------- | ---------------- | ------------------------------------------- |
| `ff f4`    | `push esp`       | Empuja el valor actual de ESP a la pila     |
| `8b 1c 24` | `mov ebx, [esp]` | Copia ese valor a EBX (relleno inofensivo)  |
| `c3`       | `ret`            | Extrae de la pila el valor empujado y salta |

El razonamiento es el siguiente: `push esp` guarda la direccion a la que apunta
ESP (el inicio del shellcode). A continuacion, `ret` recupera esa misma direccion
y salta hacia ella. La instruccion intermedia `mov ebx, [esp]` solo copia un dato
a EBX; no modifica ESP ni EIP, por lo que constituye relleno inofensivo: no altera
la estructura de la pila ni impide que el flujo aterrice en el shellcode. En
sintesis, esta secuencia se comporta como un `jmp esp`.

### 2.4 Localizar el gadget con ropper

No es necesario leer el binario manualmente. Herramientas como **ropper** (o
ROPgadget) realizan la busqueda de gadgets:

```
pip install ropper
ropper --file vulnShellCode --search "jmp esp"
ropper --file vulnShellCode --search "push esp"
```

Cuando se identifique una secuencia del tipo `push esp; ...; ret` cuyos bytes
intermedios no modifiquen ESP ni desvien el flujo, se tendra el gadget. Registre
su direccion (de la forma `0x0804....`). Esa direccion, en little-endian, es la
que se ubica en la parte de "direccion de retorno" del payload.

Tenga presente el formato little-endian: una direccion como `0x08048abc` se
escribe con los bytes en orden inverso, `\xbc\x8a\x04\x08`. En pwntools no es
necesario hacerlo manualmente; utilice `p32()`.

### 2.5 El shellcode

Es el codigo que se desea ejecutar una vez tomado el control. pwntools lo genera
con `shellcraft`:

```python
shellcode = asm(shellcraft.sh())   # lee e imprime flag.txt
# o, para obtener un shell interactivo:
# shellcode = asm(shellcraft.sh())
```

Un detalle relevante sobre la ruta: si decide usar el shellcode `cat('flag.txt')` emplea una ruta
**relativa**. En el servidor, el proceso se ejecuta con su directorio de trabajo
en la carpeta donde reside el flag, de modo que `flag.txt` se resuelve
correctamente por netcat. Si se opta por un shell con `shellcraft.sh()`, dentro
del mismo pueden ejecutarse `cat flag.txt`, `id`, entre otros.

Una precaucion adicional: `gets()` se detiene en el byte de salto de linea
(`0x0a`). El payload no puede contener ese byte en posiciones intermedias, pues se
cortaria alli. El shellcode generado por pwntools normalmente evita ya los bytes
problematicos.

---

## 3. Ensamblaje del payload

Con las tres piezas, el payload en pwntools resulta simple:

```python
payload = b'a' * OFFSET + p32(DIRECCION_DEL_GADGET) + asm(shellcraft.cat('flag.txt'))
```

Corresponde al estudiante obtener `OFFSET` (seccion 2.1) y `DIRECCION_DEL_GADGET`
(seccion 2.4). Reemplace esa linea en `exploit.py` y ejecute:

```
python exploit.py
```

---

## 4. Un detalle de red que conviene conocer

Al establecer la conexion, el prompt "Ingrese un string..." **no llega de
inmediato**. Este comportamiento es esperado: dado que la salida viaja por un
socket, la libreria estandar la mantiene en buffer y solo la vacia al final del
programa. Por esa razon, en `exploit.py` **no** se incluye un `p.readline()`
antes de enviar: de hacerlo, el script quedaria bloqueado esperando un prompt que
aun no ha salido. Envie el payload directamente.

---

## 5. Herramientas recomendas

```
pip install pwntools ropper
```

- `pwntools` para crear exploits
- `ropper` busqueda de gadgets en el binario.
- `gdb` (idealmente con pwndbg o GEF): depuracion local y medicion del offset.

---

## 6. Entregables

1. El archivo `exploit.py`
2. Una breve explicacion (un parrafo) de como lo hizo
3. El flag!
