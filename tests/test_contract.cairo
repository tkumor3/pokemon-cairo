use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::TryInto;
use starknet::ContractAddress;
use starknet::Felt252TryIntoContractAddress;
use cheatcodes::PreparedContract;
use forge_print::PrintTrait;

use pokemon_cairo::IPokemonsSafeDispatcher;
use pokemon_cairo::IPokemonsSafeDispatcherTrait;

fn deploy_pokemons() -> ContractAddress {
    let class_hash = declare('Pokemons').unwrap();
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @ArrayTrait::new()
    };
    let contract_address = deploy(prepared).unwrap();

    let contract_address: ContractAddress = contract_address.try_into().unwrap();

    contract_address
}

#[test]
fn test_get_pokemons() {
    let contract_address = deploy_pokemons();

    let safe_dispatcher = IPokemonsSafeDispatcher { contract_address };

    let pokemons = safe_dispatcher.get_pokemons().unwrap();

    assert(*pokemons.at(0).name == bulbasaur, 'Bulbasaur');
    assert(*pokemons.at(1).name == 'Pikachu', 'Pikachu');
    assert(*pokemons.at(2).name == 'Diglett', 'Diglett');
}
