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
use pokemon_cairo::Pokemons::Pokemon;

fn deploy_pokemons() -> ContractAddress {
    let class_hash = declare('Pokemons');

    let mut constructor_calldata = ArrayTrait::new();

    constructor_calldata.append(123);

    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @constructor_calldata
    };

    let contract_address = deploy(prepared).unwrap();

    contract_address
}

#[test]
fn test_get_pokemons() {
    let contract_address = deploy_pokemons();
    let safe_dispatcher = IPokemonsSafeDispatcher { contract_address };

    let pokemons = safe_dispatcher.get_pokemons().unwrap();

    assert(*pokemons.at(0).name == 'Bulbasaur', 'Bulbasaur');
    assert(*pokemons.at(1).name == 'Pikachu', 'Pikachu');
    assert(*pokemons.at(2).name == 'Diglett', 'Diglett');
}

#[test]
fn test_add_pokemon() {
    let contract_address = deploy_pokemons();
    let safe_dispatcher = IPokemonsSafeDispatcher { contract_address };
    let caller_address: ContractAddress = 123.try_into().unwrap();

    start_prank(caller_address, contract_address);

    let pokemon = Pokemon { name: 'Charmander', kind: 'Fire', likes: 0 };
    safe_dispatcher.add_pokemon(pokemon).unwrap();

    let pokemons = safe_dispatcher.get_pokemons().unwrap();
    assert(*pokemons.at(3).name == 'Charmander', *pokemons.at(3).name);
}

#[test]
fn test_get_pokemon_index_by_name() {
    let contract_address = deploy_pokemons();
    let safe_dispatcher = IPokemonsSafeDispatcher { contract_address };

    let index = safe_dispatcher.get_pokemon_index_by_name('Diglett').unwrap().unwrap();

    assert(index == 2, 'Returns wrong index for pokemon');
}

#[test]
fn test_like_pokemon() {
    let contract_address = deploy_pokemons();

    let caller_address: felt252 = 123;
    let caller_address: ContractAddress = caller_address.try_into().unwrap();

    start_prank(contract_address, caller_address);

    let safe_dispatcher = IPokemonsSafeDispatcher { contract_address };

    //Should panic if pokemon doesn't exists
    match safe_dispatcher.like_pokemon('BulbNotExists') {
        Result::Ok(_) => panic_with_felt252('shouldve panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'BulbNotExists', *panic_data.at(0));
            assert(*panic_data.at(1) == 'doesnt exists', *panic_data.at(1));
        }
    };

    //Expect increment bulbasaur likes counter
    safe_dispatcher.like_pokemon('Bulbasaur').unwrap();
    let pokemons = safe_dispatcher.get_pokemons().unwrap();
    assert(*pokemons.at(0).likes == 1, 'Bulbasaur should have one like');

    //Should panic if someone like the same pokemon twice
    match safe_dispatcher.like_pokemon('Bulbasaur') {
        Result::Ok(_) => panic_with_felt252('shouldve panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Already voted', *panic_data.at(0));
        }
    };

    stop_prank(contract_address);
    // //Set new caller_address
    let caller_address: felt252 = 1234;
    let caller_address: ContractAddress = caller_address.try_into().unwrap();

    start_prank(contract_address, caller_address);

    //Expect increment bulbasaur likes counter
    match safe_dispatcher.like_pokemon('Bulbasaur') {
        Result::Ok(e) => {},
        Result::Err(e) => {
            e.print();
        }
    }

    let pokemons = safe_dispatcher.get_pokemons().unwrap();
    assert(*pokemons.at(0).likes == 2, *pokemons.at(0).likes);
}
