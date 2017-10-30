defmodule Deck do
  @ranks ~w(Ace 2 3 4 5 6 7 8 9 10 Jack Queen King)
  @suits ~w(Clubs Diamonds Hearts Spades)

  def new do
    @suits
    |> Enum.map(&iterate_over_ranks/1)
    |> List.flatten
  end

  def deal_hand(deck) do
    deal_hands(deck, 1)
  end

  def deal_hands(deck, num_hands) do
    {deck, hands} = deal_one_card_to_hands(deck, make_hands(num_hands, []), [])
    deal_one_card_to_hands(deck, hands, [])
  end

  ### PRIVATE STUFF

  defp make_hands(0, acc), do: acc
  defp make_hands(num_hands, acc), do: make_hands(num_hands - 1, [[]|acc])

  defp deal_one_card_to_hands(deck, [], acc), do: {deck, acc |> Enum.reverse}
  defp deal_one_card_to_hands([card|deck], [hand|rest], acc) do
    deal_one_card_to_hands(deck, rest, [[card|hand]|acc])
  end

  defp iterate_over_ranks(suit) do
    @ranks |> Enum.map(&(Card.from_rank_and_suit(&1, suit)))
  end

end

defmodule Game do
  def take_turns(deck, hands, acc \\ [])
  def take_turns(deck, [], acc), do: {deck, acc |> Enum.reverse}
  def take_turns(deck=[card|rest], [hand|others], acc) do
    if Hand.value(hand) > 16 do
      take_turns(deck, others, [hand|acc])
    else
      take_turns(rest, [[card|hand]|others], acc)
    end
  end

  def winners(hands) do
    try do
      vals = hands |> Enum.map(&Hand.value/1)
      best = vals
             |> Enum.reject(&(&1 > 21))
             |> Enum.max
      vals
      |> Enum.with_index
      |> Enum.filter(fn(t) -> elem(t,0) == best end)
      |> Enum.map(fn(t) -> elem(t,1) end)
    rescue
      Enum.EmptyError -> []
    end
  end
end

defmodule Hand do
  def value(hand) do
    map = hand |> Enum.group_by(fn(c) -> elem(c,0) == "Ace" end)
    aces = map[true] || []
    others = map[false] || []
    others_val = others |> Enum.map(&Card.value/1) |> Enum.sum
    value_with_aces(length(aces), others_val)
  end

  defp value_with_aces(0, others_val), do: others_val
  defp value_with_aces(num_aces, others_val) do
    val_as_ones = others_val + num_aces
    # there is never room for two or more aces!
    if val_as_ones <= 11, do: val_as_ones + 10, else: val_as_ones
  end
end

defmodule Card do

  @value_map %{
    "Ace" => 11,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "5" => 5,
    "6" => 6,
    "7" => 7,
    "8" => 8,
    "9" => 9,
    "10" => 10,
    "Jack" => 10,
    "Queen" => 10,
    "King" => 10,
  }

  def ace_value_with(value_of_rest) do
    if value_of_rest > 11, do: 1, else: 11
  end
  def from_rank_and_suit(rank, suit) do
    {rank, suit}
  end

  def value({rank, _suit}) do
    @value_map[rank]
  end
end
