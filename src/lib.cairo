
#[starknet::interface]
trait IPokemons<TContractState> {
    fn get_pokemons(self: @TContractState) -> Array<Pokemons::Pokemon>;
    fn add_pokemon(ref self: TContractState, new_pokemon: Pokemons::Pokemon);
    fn like_pokemon(ref self: TContractState, pokemon_name: felt252);
    fn get_pokemon_index_by_name(self: @TContractState, name: felt252) -> u32;
}

#[starknet::contract]
mod Pokemons {
    use array::ArrayTrait;
    use starknet::{ContractAddress, get_caller_address};

    #[derive(Drop, Serde, Copy, storage_access::StorageAccess)]
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
    fn constructor(ref self: ContractState) {
        let bulbasaur = Pokemon { name: 'Bulbasaur', kind: 'Grass', likes: 0 };
        self.pokemons.write(0, bulbasaur);

        let pikachu = Pokemon { name: 'Pikachu', kind: 'Electric', likes: 0};
        self.pokemons.write(1, pikachu);

        let diglett = Pokemon { name: 'Diglett', kind: 'Ground', likes: 0 };
        self.pokemons.write(2, diglett);
        self.counter.write(3);
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
            let pokemons_amount = self.counter.read();
            self.pokemons.write(pokemons_amount, new_pokemon);
            self.counter.write(pokemons_amount + 1)
        }

        fn get_pokemon_index_by_name(self: @ContractState, name: felt252) -> u32 {
            let pokemons_amount = self.counter.read();
            let mut i: usize = 0;
            loop {
                if self.pokemons.read(i).name == name {
                    break;
                };
                i += 1;
            };
            i
        }

        fn like_pokemon(ref self: ContractState, pokemon_name: felt252) {
            let caller = get_caller_address();
            let pokemon_index = PokemonsImpl::get_pokemon_index_by_name(@self, pokemon_name);
            self.likes.write((caller, pokemon_index), true);
        }

    }
}
