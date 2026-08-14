# Publication-quality transformation and residual diagnostic figures
# Required packages: readxl, ggplot2, dplyr
# Usage: Rscript 09_create_diagnostic_figures.R input.xlsx output_directory

required_packages <- c("readxl", "ggplot2", "dplyr")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "Install the following R packages before running this program: ",
    paste(missing_packages, collapse = ", ")
  )
}

library(readxl)
library(ggplot2)
library(dplyr)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
  stop("Usage: Rscript 09_create_diagnostic_figures.R input.xlsx output_directory")
}

input_file <- normalizePath(args[1], mustWork = TRUE)
output_dir <- args[2]

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

transformation_data <- read_excel(input_file, sheet = "Transformation_data")
residual_data <- read_excel(input_file, sheet = "Residual_data")

diagnosis_labels <- c(
  NCI = "NCI",
  MCI = "MCI",
  DEM = "Dementia"
)

scale_labels <- c(
  Original = "Original scale",
  Transformed = "Transformed scale"
)

transformation_data <- transformation_data %>%
  mutate(
    Outcome = factor(Outcome, levels = c("MOCA", "PTAU217")),
    Diagnosis = factor(Diagnosis, levels = c("NCI", "MCI", "DEM")),
    Scale = factor(Scale, levels = c("Original", "Transformed"))
  )

residual_data <- residual_data %>%
  mutate(
    Outcome = factor(
      Outcome,
      levels = c("MOCA", "PTAU217"),
      labels = c("MoCA", "p-tau217")
    ),
    Diagnosis = factor(Diagnosis, levels = c("NCI", "MCI", "DEM"))
  )

theme_publication <- theme_bw(base_size = 10, base_family = "sans") +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(colour = "grey90", linewidth = 0.25),
    strip.background = element_rect(fill = "grey92", colour = "grey45"),
    strip.text = element_text(face = "bold", size = 9),
    axis.title = element_text(size = 10),
    axis.text = element_text(size = 8.5),
    plot.margin = margin(7, 8, 7, 8)
  )

save_figure <- function(plot, stem, width, height) {
  ggsave(
    filename = file.path(output_dir, paste0(stem, ".png")),
    plot = plot,
    width = width,
    height = height,
    units = "in",
    dpi = 300,
    bg = "white"
  )

  ggsave(
    filename = file.path(output_dir, paste0(stem, ".tiff")),
    plot = plot,
    width = width,
    height = height,
    units = "in",
    dpi = 600,
    compression = "lzw",
    bg = "white"
  )

  ggsave(
    filename = file.path(output_dir, paste0(stem, ".pdf")),
    plot = plot,
    width = width,
    height = height,
    units = "in",
    device = "pdf",
    bg = "white"
  )
}

# Figure S1: p-tau217 before and after log transformation
ptau_plot <- transformation_data %>%
  filter(Outcome == "PTAU217") %>%
  ggplot(aes(x = Value)) +
  geom_histogram(
    aes(y = after_stat(density)),
    bins = 35,
    boundary = 0,
    fill = "#4472A8",
    colour = "white",
    linewidth = 0.18
  ) +
  geom_density(colour = "#163A5F", linewidth = 0.65, adjust = 1.1) +
  facet_grid(
    rows = vars(Diagnosis),
    cols = vars(Scale),
    scales = "free",
    labeller = labeller(Diagnosis = diagnosis_labels, Scale = scale_labels)
  ) +
  labs(
    x = "Value",
    y = "Density"
  ) +
  theme_publication

save_figure(ptau_plot, "Figure_S_Transformation_p-tau217", 7.1, 7.0)

# Figure S2: MoCA before and after square-root deficit transformation
moca_plot <- transformation_data %>%
  filter(Outcome == "MOCA") %>%
  ggplot(aes(x = Value)) +
  geom_histogram(
    aes(y = after_stat(density)),
    bins = 31,
    fill = "#6B8E6B",
    colour = "white",
    linewidth = 0.18
  ) +
  geom_density(colour = "#274E27", linewidth = 0.65, adjust = 1.1) +
  facet_grid(
    rows = vars(Diagnosis),
    cols = vars(Scale),
    scales = "free",
    labeller = labeller(Diagnosis = diagnosis_labels, Scale = scale_labels)
  ) +
  labs(
    x = "Value",
    y = "Density"
  ) +
  theme_publication

save_figure(moca_plot, "Figure_S_Transformation_MoCA", 7.1, 7.0)

# Figure S3: Q-Q plots of standardized conditional residuals
residual_qq_plot <- ggplot(
  residual_data,
  aes(sample = StandardizedResidual)
) +
  stat_qq(shape = 16, size = 0.55, alpha = 0.35, colour = "#345E7D") +
  stat_qq_line(linewidth = 0.65, colour = "#B2182B") +
  facet_grid(
    rows = vars(Outcome),
    cols = vars(Diagnosis),
    scales = "free",
    labeller = labeller(Diagnosis = diagnosis_labels)
  ) +
  labs(
    x = "Theoretical normal quantiles",
    y = "Observed residual quantiles"
  ) +
  theme_publication

save_figure(residual_qq_plot, "Figure_S_Conditional_Residual_QQ", 7.1, 5.0)

# Save the plotting environment information for reproducibility.
capture.output(
  sessionInfo(),
  file = file.path(output_dir, "7_7_R_SESSION_INFO.txt")
)

message("Figures saved in: ", output_dir)
