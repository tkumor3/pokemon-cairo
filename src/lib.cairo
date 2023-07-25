#[starknet::interface]
trait IPokemons<TContractState> {
    fn add_pokemon(ref self: TContractState, amount: felt252);
    fn get_pokemons(self: @TContractState) -> felt252;
}

#[starknet::contract]
mod Pokemons {
    struct Owner {
        name: felt252,
    } 

    #[derive(storage_access::StorageAccess)]
    struct Pokemon {
        name: felt252,
        type: felt252,
        likes: felt252
        owner: Owner
    }

    #[storage]
    struct Storage {
        pokemons: LegacyMap::<felt252, Pokemon>
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: Person) {
        let owner = Owner { name: 'init' }

        let bulbasaur = Rectangle { name: 'Bulbasaur', type: 'Grass', likes: 0, owner: owner   };
        self.pokemons.write('Bulbasaur', bulbasaur)

        let pikachu = Rectangle { name: 'Pikachu', type: 'Electric', likes: 0, owner: owner   };
        self.pokemons.write('Pikachu', pikachu)

        let diglett = Rectangle { name: 'Diglett', type: 'Ground', likes: 0, owner: owner   };
        self.pokemons.write('Diglett', diglett)
    }

    #[external(v0)]
    impl PokemonsImpl of super::IPokemons<ContractState> {
        fn get_pokemons(self: @ContractState) -> {
            self.pokemons.read()
        }
    }
}
