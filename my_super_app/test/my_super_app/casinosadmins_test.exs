defmodule MySuperApp.CasinosAdminsTest do
  use MySuperApp.DataCase, async: true

  alias MySuperApp.{CasinosAdmins, Repo, Operator}

  @valid_operator_attrs %{name: "Test Operator"}
  @invalid_operator_attrs %{name: ""}

  describe "add_operator/1" do
    test "successfully adds a new operator" do
      assert {:ok, %Operator{name: "Test Operator"}} =
               CasinosAdmins.add_operator(@valid_operator_attrs)
    end

    test "fails to add an operator with invalid attributes" do
      assert {:error, changeset} = CasinosAdmins.add_operator(@invalid_operator_attrs)
      assert %Ecto.Changeset{valid?: false} = changeset
    end
  end

  describe "get_operator_name/1" do
    setup do
      operator = %Operator{name: "Operator Name"} |> Repo.insert!()
      %{operator: operator}
    end

    test "retrieves the name of the operator by id", %{operator: %Operator{id: id}} do
      assert "Operator Name" == CasinosAdmins.get_operator_name(id)
    end
  end

  describe "get_operators/0" do
    setup do
      operator1 = %Operator{name: "Operator One"} |> Repo.insert!()
      operator2 = %Operator{name: "Operator Two"} |> Repo.insert!()
      %{operator1: operator1, operator2: operator2}
    end

    test "retrieves all operators as maps", %{
      operator1: %Operator{id: id1, name: name1},
      operator2: %Operator{id: id2, name: name2}
    } do
      operators = CasinosAdmins.get_operators()

      assert %{id: id1, name: name1} in Enum.map(operators, &Map.take(&1, [:id, :name]))
      assert %{id: id2, name: name2} in Enum.map(operators, &Map.take(&1, [:id, :name]))
    end
  end

  describe "get_oper_options/0" do
    setup do
      operator1 = %Operator{name: "Operator A"} |> Repo.insert!()
      operator2 = %Operator{name: "Operator B"} |> Repo.insert!()
      %{operator1: operator1, operator2: operator2}
    end

    test "retrieves operator options as maps", %{
      operator1: %Operator{id: id1, name: name1},
      operator2: %Operator{id: id2, name: name2}
    } do
      options = CasinosAdmins.get_oper_options()
      assert %{key: name1, value: id1, disabled: false} in options
      assert %{key: name2, value: id2, disabled: false} in options
    end
  end

  describe "get_oper_name/0" do
    setup do
      operator1 = %Operator{name: "Operator X"} |> Repo.insert!()
      operator2 = %Operator{name: "Operator Y"} |> Repo.insert!()
      %{operator1: operator1, operator2: operator2}
    end

    test "retrieves names of all operators", %{
      operator1: %Operator{name: name1},
      operator2: %Operator{name: name2}
    } do
      names = CasinosAdmins.get_oper_name()
      assert name1 in names
      assert name2 in names
    end
  end
end
