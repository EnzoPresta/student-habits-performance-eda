# Notas

Este proyecto contiene el código original recuperado de la conversación anterior, adaptado para GitHub.

Cambio principal realizado:

```r
read_csv(here("student_habits_performance_dataset.csv"))
```

se reemplazó por:

```r
read_csv(here("data", "student_habits_performance_5000.csv"))
```

Esto permite que el script funcione desde la estructura del repositorio.
