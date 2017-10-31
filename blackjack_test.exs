Code.load_file("blackjack.exs", __DIR__)
ExUnit.start
ExUnit.configure trace: true


defmodule BlackjackTest do
  use ExUnit.Case

  test "create a deck" do
    deck = Deck.new
    assert length(deck) == 52
  end

  test "deal a hand" do
    deck = Deck.new
    {rest, [hand]} = Deck.deal_hand(deck)
    assert length(hand) == 2
    assert length(rest) == 50
    assert Enum.reverse(hand) ++ rest == deck
  end

  test "deal hands to multiple players" do
    deck = Deck.new
    num_hands = 3
    {rest, hands} = Deck.deal_hands(deck, num_hands)
    assert Enum.count(hands) == num_hands
    hands |> Enum.each(fn(h) -> assert Enum.count(h) == 2 end)
    assert length(rest) == 52 - (num_hands * 2)
    assert take_back(List.to_tuple(hands), num_hands - 1, []) ==
      deck |> Enum.take(num_hands * 2)
  end

  test "counts aces as 11 if room just barely allows" do
    hand = [{"Ace", "Hearts"}, {"King", "Clubs"}]
    assert Hand.value(hand) == 21
  end

  test "counts aces as 1 if need just barely be" do
    hand = [{"7", "Diamonds"}, {"4", "Clubs"}, {"Ace", "Hearts"}]
    assert Hand.value(hand) == 12
  end

  test "lets users take turns" do
    deck = Deck.new
    num_hands = 3
    {deck, hands} = Deck.deal_hands(deck, num_hands)
    Enum.each(hands, fn(h) -> refute Hand.value(h) > 15 end)
    {_deck, hands} = Game.take_turns(deck, hands)
    Enum.each(hands, fn(h) -> assert Hand.value(h) > 15 end)
  end

  test "gives users fresh cards" do
    deck = Deck.new
    num_hands = 3
    {deck, hands} = Deck.deal_hands(deck, num_hands)
    {_deck, hands} = Game.take_turns(deck, hands)
    [hand1,hand2,hand3] = hands
    refute Enum.any?(hand1, fn(card) -> Enum.member?(hand2, card) end)
    refute Enum.any?(hand2, fn(card) -> Enum.member?(hand3, card) end)
    refute Enum.any?(hand3, fn(card) -> Enum.member?(hand1, card) end)
  end

  test "determines single winner" do
    hands = [
      [{"8", "Clubs"}, {"7", "Clubs"}, {"4", "Clubs"}, {"Ace", "Clubs"}],  # 20
      [{"10", "Clubs"}, {"9", "Clubs"}, {"5", "Clubs"}, {"2", "Clubs"}],   # 26
      [{"Jack", "Clubs"}, {"6", "Clubs"}, {"3", "Clubs"}]  # 19
    ]
    assert Game.winners(hands) == [0]
  end

  test "declares winners if tie" do
    hands = [
      [{"8", "Clubs"}, {"7", "Clubs"}, {"4", "Clubs"}],  # 19
      [{"10", "Clubs"}, {"9", "Clubs"}, {"5", "Clubs"}, {"2", "Clubs"}],   # 26
      [{"Jack", "Clubs"}, {"6", "Clubs"}, {"3", "Clubs"}]  # 19
    ]
    assert Game.winners(hands) == [0,2]
  end

  test "declares no winner if all bust" do
    hands = [
      [{"10", "Clubs"}, {"9", "Clubs"}, {"5", "Clubs"}, {"2", "Clubs"}],
      [{"10", "Diamonds"}, {"9", "Diamonds"}, {"5", "Diamonds"}, {"2", "Diamonds"}],
      [{"10", "Hearts"}, {"9", "Hearts"}, {"5", "Hearts"}, {"2", "Hearts"}],
    ]
    assert Game.winners(hands) == []
  end

  test "declares no winner if no hands" do
    hands = []
    assert Game.winners(hands) == []
  end

  defp take_back(hands, which, acc) do
    case elem(hands, which) do
      [] -> acc
      [card|rest] ->
        next = if which == 0, do: tuple_size(hands) - 1, else: which - 1
        take_back(put_elem(hands, which, rest), next, [card|acc])
    end
  end

end
