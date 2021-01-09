defmodule TargetApp do
  @moduledoc """
  Documentation for TargetApp.
  """

  @doc """
  Hello world.

  ## Examples

      iex> TargetApp.hello
      :world

  """
  def hello do
    :"mix upload.hotswap"
  end
end
