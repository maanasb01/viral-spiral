defmodule ViralSpiral.Canon.Deck do
  @moduledoc """

  """
  alias ViralSpiral.Canon.Deck
  alias ViralSpiral.Canon.Deck.CardSet
  alias ViralSpiral.Canon.Card.Sparse
  alias ViralSpiral.Canon.Card

  @set_opts_default [affinities: [:cat, :sock], biases: [:red, :yellow]]

  @doc """
  Partition cards into sets.
  """
  @spec create_sets(list(Card.t()), keyword()) :: CardSet.card_sets()
  def create_sets(cards, opts \\ @set_opts_default) do
    affinities = opts[:affinities]
    biases = opts[:biases]

    common_cards = cards |> Enum.filter(&(&1.type in [:topical, :conflated]))
    affinity_cards = cards |> Enum.filter(&(&1.type == :affinity and &1.target in affinities))
    bias_cards = cards |> Enum.filter(&(&1.type == :bias and &1.target in biases))

    cards = common_cards ++ affinity_cards ++ bias_cards

    grouped_card = cards |> Enum.group_by(&Deck.Card.key(&1))

    Enum.reduce(
      Map.keys(grouped_card),
      %{},
      &Map.put(
        &2,
        &1,
        Enum.map(grouped_card[&1], fn card -> Deck.CardSet.make_member(card) end) |> MapSet.new()
      )
    )
  end

  @doc """
  Probabilistically draw a card with specific constraits.

  When the number of cards of a card type under a tgb becomes 0,we short circuit the tgb condition
  and draw a card without considering tgb.
  This is not intuitive and can be fixed by writing a lot of cards for lower tgb level's
  """
  @spec draw_card(CardSet.card_sets(), CardSet.key_type(), integer()) :: Sparse.t()
  def draw_card(card_sets, set_key, chaos) do
    # {_, veracity, _} = set_key

    card_set_tgb = card_sets[set_key] |> filter_tgb(chaos)
    card_set_tgb_len = card_set_tgb |> MapSet.size()

    case card_set_tgb_len do
      0 -> card_sets[set_key] |> choose_one()
      _ -> card_set_tgb |> choose_one()
    end
  end

  defp filter_tgb(set, tgb) do
    set
    |> Enum.filter(&(&1.tgb <= tgb))
    |> MapSet.new()
  end

  defp choose_one(list) do
    length = list |> Enum.to_list() |> length
    length = if length == 0, do: 1, else: length
    ix = :rand.uniform(length) - 1
    list |> Enum.at(ix)
  end

  @doc """
  Removes a card from set.
  """
  @spec remove_card(any(), CardSet.key_type(), CardSet.member()) :: any()
  def remove_card(card_sets, card_set_key, card_set_member) do
    {_, new_sets} =
      Map.get_and_update(card_sets, card_set_key, fn set ->
        {set, MapSet.delete(set, card_set_member)}
      end)

    new_sets
  end

  @doc """

  """
  @spec size(sets :: CardSet.card_sets(), CardSet.key_type()) :: non_neg_integer()
  def size(sets, set_key) do
    case sets[set_key] do
      nil -> -1
      _ -> size!(sets, set_key)
    end
  end

  @spec size(sets :: CardSet.card_sets(), CardSet.key_type()) :: non_neg_integer()
  def size!(sets, set_key) do
    sets[set_key]
    |> MapSet.size()
  end
end
