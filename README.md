Johan Barrera — 1152538 
Arquitectura de computadores B (Unidad 5)
Universidad Francisco de Paula Santander (UFPS)

# Barrera-post1-u5
# Descripción
El laboratorio contrapone dos mecanismos: la **emulación** (Parte 1, DOSBox recrea por software el hardware x86 de 16 bits y el entorno DOS) y la **virtualización** 
(Parte 2, VirtualBox expone hardware casi real a un sistema operativo huésped completo).

#Paso 7
| Corrida | cycles | Hora inicial | Hora final | Duración observada |
|--------:|-------:|--------------|------------|--------------------|
| 1       | 8000   | 11:35:12:89  | 11:35:45:68 | 3279 centésimas (32,79 s) |
| 2       | 1000   | 11:51:16:11  | 11:55:38:49 | 26238 centésimas (262,38 s) |
| 3       | 20000  | 12:01:54:02  | 12:02:07:15 | 1313 centésimas (13,13 s) |

## Paso 8 — Decisión técnica 1 (Parte 1, Paso 8): ¿qué valor de `cycles` es el correcto para este laboratorio?
**Decisión: usar un valor fijo, `cycles=8000`.**

Con `cycles=max`, DOSBox emula tantas instrucciones por milisegundo como el procesador anfitrión permita, de modo que en un equipo moderno el bucle de 
`ciclos.com` (2000 × 65 535 iteraciones fijadas en el código fuente) termina casi instantáneamente. La duración deja de depender del programa y pasa a depender 
del hardware del anfitrión, por lo que la medición pierde su propósito: la diferencia entre la hora inicial y la final ya no refleja el valor de `cycles`, sino 
qué tan rápido es cada equipo, y los resultados de distintos estudiantes dejan de ser comparables.

Un valor fijo como 8000 desacopla la velocidad emulada de la máquina real: cada milisegundo de tiempo virtual ejecuta un número constante de instrucciones, así 
que la misma corrida produce duraciones equivalentes en equipos distintos, siempre que el anfitrión pueda sostener esa carga (algo trivial a 8000), y la tabla del 
Paso 7 se vuelve reproducible. Tampoco `cycles=auto` es adecuado: intenta adivinar lo que el programa activo necesita y ajusta la velocidad dinámicamente, lo que 
reintroduce variabilidad entre corridas y entre equipos.

Fuera de este laboratorio, `cycles=max` o `cycles=auto` sí son la opción correcta cuando importa el rendimiento y no la fidelidad temporal: por ejemplo, al 
ejecutar herramientas o software de productividad reescrito para DOS (compiladores, editores, hojas de cálculo), donde terminar antes es una ventaja y ningún 
comportamiento depende de la velocidad del procesador original. `auto` resulta además cómodo para alternar entre programas con requisitos de velocidad distintos 
sin editar la configuración.

## Paso 9 — Decisión técnica 2 (Parte 1, Paso 9): tiempo emulado en DOSBox frente a ciclos de CPU reales

**Decisión: `cycles` no debe compararse con la frecuencia ni con los ciclos de reloj reales del anfitrión.**

El valor `cycles=8000` indica que DOSBox intenta emular unas 8000 instrucciones x86 por milisegundo de tiempo virtual, es decir, unos 8 millones por segundo 
emulado. La frecuencia del procesador anfitrión (varios GHz) cuenta, en cambio, ciclos de reloj físicos del silicio por segundo real. Compararlos directamente 
sería un error de categoría: una magnitud mide instrucciones emuladas por unidad de tiempo virtual y la otra, ciclos físicos por unidad de tiempo real. Por la 
misma razón, las centésimas que `ciclos.com` lee con la función 2Ch provienen del reloj interno emulado de DOSBox y no de un contador de hardware.

Además, cada instrucción x86 de 16 bits emulada exige que DOSBox la interprete por software con un número variable de instrucciones nativas (decodificar, acceder 
a los registros y a la memoria emulados, actualizar flags, atender interrupciones). Por eso el anfitrión ejecuta muchísimos más ciclos reales por segundo de los 
que sugiere `cycles`, y este valor no permite deducir el uso real de CPU del proceso `DOSBox.exe`: este depende del costo de interpretación de cada instrucción y 
del tiempo que el proceso permanece en espera dentro de cada milisegundo.

Para estimar el consumo real se debe medir en el anfitrión: el Administrador de tareas o el Monitor de recursos (Windows), o `top`/`htop` (Linux), para el 
porcentaje de CPU del proceso; y, si se requieren ciclos físicos exactos, un perfilador como `perf stat -e cycles -p <PID>` en Linux o Intel VTune / Windows 
Performance Analyzer en Windows.

# PARTE 2 — VirtualBox: creación y gestión de máquinas virtuales
## Checkpoint 5 — Reasignación de recursos de la VM

Se modificó la configuración de la máquina virtual Lab5-Alpine mediante VBoxManage modifyvm, aumentando los procesadores virtuales de 1 a 2 y la memoria RAM de 
1024 MB a 2048 MB.

Después de reiniciar Alpine Linux, se ejecutó nproc, obteniendo como resultado 2 procesadores. Posteriormente, mediante free -m, se verificó que el sistema 
reconocía 1976 MiB de memoria RAM, de los cuales 60 MiB estaban en uso en el momento de la medición.

Los resultados confirman que VirtualBox aplicó correctamente la reasignación de recursos sin necesidad de reinstalar el sistema operativo.

