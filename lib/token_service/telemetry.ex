defmodule TokenService.Telemetry do
  @moduledoc """
  Telemetry setup and metrics definitions.
  """

  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000},
      {TelemetryMetricsPrometheus.Core, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # HTTP Metrics (automatic from Plug.Cowboy)
      counter("http.request.count",
        tags: [:method, :path],
        description: "Total number of HTTP requests"
      ),

      # Token Validation Metrics (custom)
      counter("token_service.validation.count",
        tags: [:result],
        description: "Total number of token validations by result (success/failed)"
      ),
      counter("token_service.validation.failure_reasons",
        tags: [:reason],
        description: "Token validation failures by reason",
        keep: fn metadata -> Map.has_key?(metadata, :reason) end
      ),

      # VM Metrics
      last_value("vm.memory.total", unit: :byte),
      last_value("vm.total_run_queue_lengths.total"),
      last_value("vm.total_run_queue_lengths.cpu"),
      last_value("vm.system_counts.process_count")
    ]
  end

  defp periodic_measurements do
    [
      {__MODULE__, :vm_measurements, []}
    ]
  end

  def vm_measurements do
    memory = :erlang.memory()
    :telemetry.execute([:vm, :memory], %{total: memory[:total]}, %{})

    # total_run_queue_lengths returns 0 or {Total, CPU, IO}
    run_queue_lengths =
      case :erlang.statistics(:total_run_queue_lengths) do
        0 -> %{total: 0, cpu: 0}
        {total, cpu, _io} -> %{total: total, cpu: cpu}
        total when is_integer(total) -> %{total: total, cpu: 0}
      end

    :telemetry.execute([:vm, :total_run_queue_lengths], run_queue_lengths, %{})

    :telemetry.execute(
      [:vm, :system_counts],
      %{process_count: :erlang.system_info(:process_count)},
      %{}
    )
  end
end
