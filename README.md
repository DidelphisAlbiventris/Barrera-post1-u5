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

## Paso 7: Decisión técnica — Selección del modo de red y sus implicaciones de seguridad

Para el escenario de este laboratorio, considero que **NAT es la opción más adecuada como configuración de red predeterminada**, debido a que permite que la máquina virtual acceda a internet sin exponer directamente sus servicios a los demás dispositivos de la red local. Durante las pruebas realizadas con Alpine Linux, la máquina obtuvo la dirección `10.0.2.15` y consiguió comunicarse con `8.8.8.8`, confirmando su conectividad externa. NAT permite iniciar conexiones desde la máquina virtual hacia internet, mientras que las conexiones entrantes desde otros equipos requieren una configuración adicional, como el reenvío de puertos.

Por otro lado, **Host-Only resulta especialmente útil para prácticas de redes y administración de sistemas**, ya que establece una red privada entre el anfitrión y la 
máquina virtual. En nuestro experimento, Alpine utilizó la dirección `192.168.56.101` y Windows consiguió comunicarse con ella. Al intentar acceder a `8.8.8.8`, se obtuvo 
el mensaje `Network unreachable`, demostrando el aislamiento de internet. Su principal desventaja es la pérdida de conectividad externa, que impide descargar paquetes sin 
modificar la configuración.

Finalmente, **Bridge representa un mayor riesgo de seguridad para este escenario**, porque incorpora la máquina virtual a la misma red local que el anfitrión, permitiendo 
potencialmente que otros dispositivos accedan a sus servicios, como SSH. Esto aumenta la superficie de ataque si existen servicios mal configurados. Por estas razones, 
recomiendo NAT para el uso cotidiano del laboratorio, Host-Only para experimentos aislados y Bridge únicamente cuando se necesite comunicación directa con otros equipos de 
la red.

---

## Paso 8: Decisión técnica — Disco fijo frente a dinámico y asignación de CPU/RAM

Para comparar el rendimiento de los discos virtuales se utilizaron dos unidades VDI: un disco dinámico de 10 GB y otro fijo de 4 GB. Se ejecutó el comando `dd` para escribir 200 MiB de datos en cada uno y registrar sus tiempos de ejecución.

Los resultados mostraron que **el disco dinámico fue más rápido en la prueba realizada**, completando la escritura en 0,80 segundos, con una velocidad reportada de 250,5 MB/s. En comparación, el disco fijo tardó 0,95 segundos, alcanzando 210,5 MB/s. La diferencia fue de aproximadamente 0,15 segundos a favor del disco dinámico.

Aunque los discos fijos tienen la ventaja teórica de evitar el costo asociado al crecimiento progresivo del archivo VDI, esta característica no garantiza un rendimiento 
superior. Los resultados pueden verse afectados por la caché de escritura, el sistema de archivos y las condiciones del anfitrión. Además, como se ejecutó `sync` después de 
la medición, los tiempos registrados no representan necesariamente la finalización de todas las escrituras físicas.

**Considero que el almacenamiento dinámico es la mejor elección para este laboratorio**, no solo por su resultado en la medición, sino porque permite utilizar el espacio 
físico del anfitrión de manera más eficiente. Un disco dinámico aumenta el tamaño de su archivo según los datos almacenados, mientras que uno fijo reserva desde el 
principio toda su capacidad. Esto resulta especialmente importante para estudiantes con recursos de almacenamiento limitados.

Respecto a la asignación de recursos, se incrementó la configuración de la máquina virtual de 1 a 2 procesadores y de 1024 a 2048 MB de RAM. Las pruebas con `nproc` y `free -m` confirmaron que Alpine reconoció **2 procesadores y 1976 MiB de memoria disponible para el sistema**.

Esta configuración es razonable para una máquina virtual de laboratorio, porque proporciona recursos suficientes para ejecutar comandos y realizar pruebas sin consumir una 
proporción excesiva de la capacidad del anfitrión. Asignar todos los procesadores o la mayor parte de la RAM a una sola máquina virtual sería una mala práctica, puesto que 
podría perjudicar el rendimiento de Windows y las demás aplicaciones.

En conclusión, recomiendo utilizar **un disco dinámico, 2 CPU virtuales y 2048 MB de RAM** para este laboratorio, priorizando el equilibrio entre rendimiento, 
disponibilidad de recursos y eficiencia de almacenamiento.

