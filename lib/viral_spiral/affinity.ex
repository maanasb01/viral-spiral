defmodule ViralSpiral.Affinity do
  alias ViralSpiral.Affinity
  import ViralSpiral.Room.EngineConfig.Guards

  defstruct target: nil

  @labels %{
    cat: "Cat",
    sock: "Sock",
    highfive: "High Five",
    houseboat: "Houseboat",
    skub: "Skub"
  }

  @type target :: :cat | :sock | :high_five | :houseboat | :skub
  @type t :: %__MODULE__{
          target: target()
        }

  def label(target) when is_affinity(target) do
    @labels[target]
  end

  def label(%Affinity{} = affinity) do
    @labels[affinity.target]
  end

  @spec valid?(atom()) :: boolean()
  def valid?(affinity) do
    affinity in Map.keys(@labels)
  end
end
