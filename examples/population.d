import std.stdio;
import std.random;
import std.range;

import stochastic.gillespie;

void birth( Gillespie population, ref size_t density ) {
		auto growthId = population.newEventId;
		population.addEvent( growthId, 0.18, 
				delegate () => growth( population, density, growthId, 0 ) );
		density += 1;
		auto deathId = population.newEventId;
		population.addEvent( deathId, 0.02, 
				delegate () => death( population, density, growthId, deathId ));
}

void growth( Gillespie population, ref size_t density, 
		EventId growthId, size_t stage ) {
		population.delEvent( growthId );
		if (stage > 4) {
			birth( population, density );
			population.addEvent( growthId, 0.18, 
				delegate () => growth( population, density, growthId, 0 ) );
		} else {
			population.addEvent( growthId, 0.18, 
				delegate () => growth( population, density, growthId, stage + 1 ) );
		}
}

void death( Gillespie population, ref size_t density, EventId growthId,
		EventId deathId ) {
	population.delEvent( growthId );
	population.delEvent( deathId );
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
