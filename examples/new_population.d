import std.stdio;
import std.random;
import std.range;

import stochastic.gillespie;


void birth( Gillespie population, ref size_t density ) {
		auto growth_id = population.new_event_id;
		population.add_event( growth_id, 0.02, 
				delegate () => growth( population, density, growth_id, 0 ) );
		density += 1;
		auto death_id = population.new_event_id;
		population.add_event( death_id, 0.02, 
				delegate () => death( population, density, growth_id, death_id ));
}

void growth( Gillespie population, ref size_t density, 
		event_id growth_id, size_t stage ) {
		population.del_event( growth_id );
		if (stage > 5) {
			birth( population, density );
			population.add_event( growth_id, 0.02, 
				delegate () => growth( population, density, growth_id, 0 ) );
		} else {
			population.add_event( growth_id, 0.02, 
				delegate () => growth( population, density, growth_id, stage + 1 ) );
		}
}

void death( Gillespie population, ref size_t density, event_id growth_id,
		event_id death_id ) {
	population.del_event( growth_id );
	population.del_event( death_id );
	density -= 1;
}

void simulate_population() {
	static Random gen;

	auto population = new Gillespie();

	size_t density = 0;

	foreach ( i; 0..100 ) {
		birth( population, density );
	}

	real t = 0;

	foreach ( state; population.simulation( gen ) ) {
		if (state[0] > 400) {
			writeln( state[0], " ", density );
			break;
		}

		state[1]();
		if (density == 0) {
			writeln( "Population went extinct." );
			break;
		}
	}
}

void main() {
	import std.datetime;
	auto r = benchmark!(simulate_population)(100);
	writeln( "Simulation took (in milliseconds): ", r[0].msecs );
}
