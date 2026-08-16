# Publication-quality simulation trade-off figure
# Required packages: ggplot2, dplyr
# In RStudio, the program prompts for the input file and output directory.
# From a terminal, provide both paths as arguments to Rscript.

required_packages <- c("ggplot2", "dplyr")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "Install the following R packages before running this program: ",
    paste(missing_packages, collapse = ", ")
  )
}

library(ggplot2)
library(dplyr)

if (interactive()) {
  message("Select simulation_tradeoff_summary.csv")
  input_file <- file.choose()

  if (.Platform$OS.type == "windows") {
    output_dir <- utils::choose.dir(
      default = dirname(input_file),
      caption = "Select the directory for Figure_Simulation_Tradeoff.pdf"
    )
    if (is.na(output_dir)) {
      stop("No output directory was selected.")
    }
  } else {
    output_dir <- dirname(input_file)
    message("The figure will be written beside the selected CSV file.")
  }
} else {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 2) {
    stop(
      "Usage: Rscript 10_create_simulation_tradeoff_figure.R ",
      "simulation_tradeoff_summary.csv output_directory"
    )
  }

  input_file <- args[1]
  output_dir <- args[2]
}

input_file <- normalizePath(input_file, mustWork = TRUE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

plot_data <- read.csv(input_file, stringsAsFactors = FALSE) %>%
  mutate(
    N = factor(N, levels = c(2500, 5000, 10000)),
    M = as.integer(M),
    Speedup = as.numeric(Speedup),
    ConvergencePercent = as.numeric(ConvergencePercent)
  ) %>%
  filter(M > 1) %>%
  mutate(
    LabelX = Speedup + 1.2,
    LabelY = ConvergencePercent + case_when(
      N == "5000" & M == 2 ~ -2.0,
      N == "10000" & M == 2 ~ 1.0,
      TRUE ~ 1.4
    )
  ) %>%
  arrange(N, M)

if (nrow(plot_data) == 0) {
  stop("No partitioned simulation configurations were found in the CSV file.")
}

palette_n <- c(
  "2500" = "#0072B2",
  "5000" = "#E69F00",
  "10000" = "#009E73"
)

tradeoff_plot <- ggplot(
  plot_data,
  aes(
    x = Speedup,
    y = ConvergencePercent,
    colour = N,
    group = N
  )
) +
  geom_hline(
    yintercept = 95,
    linewidth = 0.45,
    linetype = "dashed",
    colour = "grey45"
  ) +
  annotate(
    "text",
    x = 53,
    y = 96.4,
    label = "95% complete convergence",
    hjust = 1,
    size = 3,
    colour = "grey35"
  ) +
  geom_line(linewidth = 0.65) +
  geom_point(size = 2.8) +
  geom_text(
    aes(x = LabelX, y = LabelY, label = paste0("M=", M)),
    hjust = 0,
    size = 2.8,
    show.legend = FALSE
  ) +
  scale_colour_manual(
    values = palette_n,
    labels = c("N=2,500", "N=5,000", "N=10,000"),
    name = NULL
  ) +
  scale_x_continuous(
    name = "Median sequential speed-up relative to full-data REML",
    limits = c(0, 55),
    breaks = seq(0, 50, 10),
    expand = expansion(mult = c(0, 0))
  ) +
  scale_y_continuous(
    name = "Complete-configuration convergence (%)",
    limits = c(25, 102),
    breaks = c(40, 60, 80, 100),
    expand = expansion(mult = c(0, 0))
  ) +
  theme_bw(base_size = 10, base_family = "sans") +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(colour = "grey88", linewidth = 0.25),
    legend.position = "inside",
    legend.position.inside = c(0.13, 0.18),
    legend.background = element_rect(fill = "white", colour = NA),
    legend.key = element_blank(),
    axis.title = element_text(colour = "grey15"),
    axis.text = element_text(colour = "grey25"),
    plot.margin = margin(8, 12, 8, 8)
  )

output_file <- file.path(output_dir, "Figure_Simulation_Tradeoff.pdf")
ggsave(
  filename = output_file,
  plot = tradeoff_plot,
  width = 7,
  height = 4.67,
  units = "in",
  device = cairo_pdf
)

writeLines(capture.output(sessionInfo()), file.path(output_dir, "simulation_figure_R_session_info.txt"))
message("Figure saved to: ", normalizePath(output_file, mustWork = TRUE))
