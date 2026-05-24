# ¿Cómo se relaciona el GPA previo con el puntaje del examen?
# ¿Cómo es la relación entre la ansiedad y el estrés con el puntaje del examen?
# ¿Existen diferencias de puntaje de examen según género y condición laboral?

# 0) Carga de librerías ----------------------------------------------
library(tidyverse)      # manipulación de datos + ggplot2
library(patchwork)      # combinar gráficos
library(knitr)          # tablas con kable()
library(kableExtra)     # estilo para kable()
library(here)           # rutas relativas
library(RColorBrewer)   # paletas de colores

# 1) Leer datos --------------------------------------------------------
df <- read_csv(here("data", "student_habits_performance_dataset.csv"))

# 2) Crear categoría “Reprobado / Aprobado” ---------------------------
df <- df |>
  mutate(
    categoria_puntaje = if_else(
      exam_score >= 60, "Aprobado", "Reprobado"
    ) |>
      factor(levels = c("Reprobado","Aprobado"))
  )

# --------------------  
# UNIVARIADO
# --------------------

# 3) Resumen de variables numéricas ------------------------------------
num_vars <- df |>
  select(where(is.numeric), -student_id)

resumen_num <- sapply(num_vars, summary, digits = 2)
knitr::kable(
  t(resumen_num),
  caption   = "Medidas de posición de variables numéricas",
  digits    = 2,
  col.names = rownames(resumen_num)
) |>
  kable_styling("striped", full_width = FALSE)

# 4) Comparación por Reprobado/Aprobado -------------------------------
df |>
  group_by(categoria_puntaje) |>
  summarise(
    media_GPA      = mean(previous_gpa,       na.rm = TRUE),
    sd_GPA         = sd(previous_gpa,         na.rm = TRUE),
    media_horas    = mean(study_hours_per_day,na.rm = TRUE),
    sd_horas       = sd(study_hours_per_day,  na.rm = TRUE),
    media_ansiedad = mean(exam_anxiety_score, na.rm = TRUE),
    sd_ansiedad    = sd(exam_anxiety_score,   na.rm = TRUE),
    media_estres   = mean(stress_level,       na.rm = TRUE),
    sd_estres      = sd(stress_level,         na.rm = TRUE),
    n              = n()
  ) |>
  kable(
    caption = "Media y desviación por categoría de examen",
    digits  = 2
  ) |>
  kable_styling("striped", full_width = FALSE)

# 5) Percentiles de exam_score -----------------------------------------
percentiles <- quantile(df$exam_score,
                        probs = c(0.10,0.25,0.50,0.75,0.90),
                        na.rm = TRUE)
tibble(
  Percentil = names(percentiles),
  Valor      = percentiles
) |>
  kable(
    caption = "Percentiles de exam_score",
    digits  = 2
  ) |>
  kable_styling("striped", full_width = FALSE)

# 6) Distribución de exam_score ----------------------------------------
p_hist_examen <- ggplot(df, aes(x = exam_score)) +
  geom_histogram(binwidth = 5, fill = "mediumpurple",
                 color = "white", alpha = 0.8) +
  labs(title = "Distribución de exam_score",
       x = "Puntaje del examen", y = "Frecuencia") +
  theme_minimal()

# Mostrar histogram + boxplot
p_hist_examen

# 7) Distribución de stress_level --------------------------------------
p_hist_estres <- ggplot(df, aes(x = stress_level)) +
  geom_histogram(binwidth = 1, fill = "steelblue",
                 color = "white", alpha = 0.7) +
  labs(title = "Distribución de stress_level",
       x = "Nivel de estrés", y = "Frecuencia") +
  theme_minimal()

# Mostrar histogram + boxplot
p_hist_estres

# 8) Frecuencias de variables categóricas ------------------------------
categoricas <- c(
  "gender", "part_time_job", "major",
  "diet_quality", "parental_education_level",
  "internet_quality", "extracurricular_participation"
)

for (var in categoricas) {
  df |>
    count(.data[[var]], name = "abs_freq") |>
    mutate(
      rel_freq = abs_freq / sum(abs_freq),
      cum_abs   = cumsum(abs_freq),
      cum_rel   = cumsum(rel_freq)
    ) |>
    kable(
      caption = paste("Frecuencias de", var),
      digits  = 2
    ) |>
    kable_styling("striped", full_width = FALSE) |>
    print()
}

# 9) Correlaciones con exam_score --------------------------------------
cor_df <- df |>
  summarise(
    across(
      .cols = where(is.numeric) & !matches("student_id|exam_score"),
      .fns  = ~ cor(.x, exam_score, use = "pairwise.complete.obs")
    )
  ) |>
  pivot_longer(
    cols      = everything(),
    names_to  = "Variable",
    values_to = "Coef"
  )

cor_df |>
  kable(
    caption = "Correlaciones de cada variable numérica con exam_score",
    digits  = 3
  ) |>
  kable_styling("striped", full_width = FALSE)


p_bar_cor <- ggplot(cor_df, aes(x = reorder(Variable, Coef), y = Coef)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(title = "Correlaciones con exam_score",
       x = NULL, y = "Coeficiente de Pearson") +
  theme_minimal()

# Mostrar barplot de correlaciones
p_bar_cor

# --------------------  
# BIVARIADO
# --------------------

# 10) Boxplots por género y trabajo parcial ----------------------------
pal_gen <- brewer.pal(3, "Dark2")
pal_job <- brewer.pal(3, "Set2")[1:2]

p_box_gen <- ggplot(df, aes(x = gender, y = exam_score, fill = gender)) +
  geom_boxplot() +
  scale_fill_manual(values = pal_gen) +
  labs(title = "exam_score por Género",
       x = "Género", y = "Puntaje examen") +
  theme_minimal() + theme(legend.position = "none")

p_box_job <- ggplot(df, aes(x = part_time_job, y = exam_score, fill = part_time_job)) +
  geom_boxplot() +
  scale_fill_manual(values = pal_job) +
  labs(title = "exam_score por Trabajo parcial",
       x = "Trabajo parcial", y = "Puntaje examen") +
  theme_minimal() + theme(legend.position = "none")

(p_box_gen | p_box_job)

# 11) Scatter GPA vs exam_score ----------------------------------------
set.seed(123)
muestra <- df |> sample_n(500)

p_gpa_all <- ggplot(muestra, aes(x = previous_gpa, y = exam_score)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  labs(title = "GPA vs exam_score (general)",
       x = "previous_gpa", y = "exam_score") +
  theme_minimal()

p_gpa_cat <- ggplot(muestra, aes(x = previous_gpa, y = exam_score,
                                 color = categoria_puntaje)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE) +
  scale_color_brewer(palette = "Dark2", name = "Resultado") +
  labs(title = "GPA vs exam_score por Resultado",
       x = "previous_gpa", y = "exam_score") +
  theme_minimal() + theme(legend.position = "bottom")

(p_gpa_all | p_gpa_cat)

# 12) Ansiedad vs exam_score (boxplot) ---------------------------------
p_ansiedad <- ggplot(df, aes(x = factor(exam_anxiety_score),
                             y = exam_score,
                             fill = categoria_puntaje)) +
  geom_boxplot(position = "dodge") +
  scale_fill_brewer(palette = "Dark2") +
  labs(title = "Ansiedad vs exam_score",
       x = "exam_anxiety_score", y = "exam_score") +
  theme_minimal() + theme(legend.position = "bottom")

p_ansiedad

# 13) Estrés vs exam_score (scatter) ----------------------------------
p_estres <- ggplot(muestra, aes(x = stress_level,
                                y = exam_score,
                                color = categoria_puntaje)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE) +
  scale_color_brewer(palette = "Dark2") +
  labs(title = "Estrés vs exam_score",
       x = "stress_level", y = "exam_score") +
  theme_minimal() + theme(legend.position = "bottom")

p_estres