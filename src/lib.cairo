#[starknet::interface]
trait IPokemons<TContractState> {
    fn get_pokemons(self: @TContractState) -> Array<Pokemons::Pokemon>;
    fn add_pokemon(ref self: TContractState, new_pokemon: Pokemons::Pokemon);
    fn like_pokemon(ref self: TContractState, pokemon_name: felt252);
    fn get_pokemon_index_by_name(self: @TContractState, name: felt252) -> Option<u32>;
}

#[starknet::contract]
mod Pokemons {
    use array::ArrayTrait;
    use starknet::{ContractAddress, get_caller_address};
    use option::OptionTrait;
    use debug::PrintTrait;
    // use openzeppelin::access::ownable::Ownable;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Added: Added,
        Voted: Voted
    }
    #[derive(Drop, starknet::Event)]
    struct Added {
        creator: ContractAddress,
        pokemon_name: felt252,
    }
    #[derive(Drop, starknet::Event)]
    struct Voted {
        voter: ContractAddress,
        pokemon_name: felt252,
    }
    #[derive(Drop, starknet::Event)]
    struct StoredName {
        #[key]
        user: ContractAddress,
        name: felt252
    }

    #[derive(Drop, Serde, Copy, starknet::Store)]
    struct Pokemon {
        name: felt252,
        kind: felt252,
        likes: felt252,
    }

    #[storage]
    struct Storage {
        pokemons: LegacyMap::<u32, Pokemon>,
        likes: LegacyMap::<(ContractAddress, u32), bool>,
        counter: u32
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        // Ownable.transfer_ownership(owner);
        self.counter.write(0);
        let bulbasaur = Pokemon { name: 'Bulbasaur', kind: 'Grass', likes: 0 };
        InternalFunctions::_add_pokemon(ref self, owner, bulbasaur);

        let pikachu = Pokemon { name: 'Pikachu', kind: 'Electric', likes: 0 };
        InternalFunctions::_add_pokemon(ref self, owner, pikachu);

        let diglett = Pokemon { name: 'Diglett', kind: 'Ground', likes: 0 };
        InternalFunctions::_add_pokemon(ref self, owner, diglett);
    }

    #[external(v0)]
    impl PokemonsImpl of super::IPokemons<ContractState> {
        fn get_pokemons(self: @ContractState) -> Array<Pokemon> {
            let pokemons_amount = self.counter.read();
            let mut pokemons: Array<Pokemon> = ArrayTrait::new();
            let mut i: usize = 0;
            loop {
                if i == pokemons_amount {
                    break;
                }
                pokemons.append(self.pokemons.read(i));
                i += 1;
            };
            pokemons
        }

        fn add_pokemon(ref self: ContractState, new_pokemon: Pokemon) {
            let caller = get_caller_address();
            InternalFunctions::_add_pokemon(ref self, caller, new_pokemon);
        }

        fn get_pokemon_index_by_name(self: @ContractState, name: felt252) -> Option<u32> {
            let pokemons_amount = self.counter.read();
            let mut i: usize = 0;
            let mut index: Option<u32> = Option::None(());
            loop {
                if self.pokemons.read(i).name == name {
                    index = Option::Some(i);
                    break;
                };
                i += 1;
                if i == pokemons_amount {
                    break;
                };
            };
            index
        }

        fn like_pokemon(ref self: ContractState, pokemon_name: felt252) {
            let caller = get_caller_address();
            let pokemon_index = PokemonsImpl::get_pokemon_index_by_name(@self, pokemon_name);

            match pokemon_index {
                Option::Some(val) => {},
                Option::None(_) => {
                    let mut data = ArrayTrait::new();
                    data.append(pokemon_name);
                    data.append('doesnt exists');
                    panic(data)
                }
            };
            let pokemon_index = pokemon_index.unwrap();
            let hasVoted = self.likes.read((caller, pokemon_index));
            if hasVoted == true {
                let mut data = ArrayTrait::new();
                data.append('Already voted');
                panic(data);
            }

            self.likes.write((caller, pokemon_index), true);
            let mut pokemon = self.pokemons.read(pokemon_index);
            pokemon.likes += 1;
            self.pokemons.write(pokemon_index, pokemon);
            self.emit(Event::Voted(Voted { voter: caller, pokemon_name: pokemon_name }));
        }
    }
    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _add_pokemon(ref self: ContractState, caller: ContractAddress, new_pokemon: Pokemon) {
            let pokemons_amount = self.counter.read();

            let pokemon_index_option = if pokemons_amount == 0 {
                Option::None(())
            } else {
                PokemonsImpl::get_pokemon_index_by_name(@self, new_pokemon.name)
            };

            match pokemon_index_option {
                Option::Some(val) => {
                    let mut data = ArrayTrait::new();
                    data.append('Name is used');
                    panic(data);
                },
                Option::None(_) => {
                    self.pokemons.write(pokemons_amount, new_pokemon);
                    self.counter.write(pokemons_amount + 1);
                }
            };
            self.emit(Event::Added(Added { creator: caller, pokemon_name: new_pokemon.name }));
        }
    }
}
