import std.stdio;
import std.random;

import stochastic.gillespie;

abstract class Event : BaseEvent {
	int execute();
}

class GrowthEvent : Event {
	this( EventList my_population ) { 
		rate = 0.18;
		population = my_population;
	}

	override int execute() {
		growth_state++;
		if (growth_state>5) {
			auto gev = new GrowthEvent( population );
			population.add_event( gev );
			auto dev = new DeathEvent( gev );
			population.add_event( dev );
			growth_state = 0;
			return 1;
		}
		return 0;
	}

	private:
		size_t growth_state = 0;
		EventList population;
}

class DeathEvent : Event {
	this( GrowthEvent my_growth_event ) { 
		rate = 0.02;
		growth_event = my_growth_event;
	}

	override int execute() {
		growth_event.rate = 0;
		rate = 0;
		return -1;
	}
	private:
		GrowthEvent growth_event;
}

void simulate_population() {
	Random gen;

	EventList population = new EventList();

	size_t density = 100;

	foreach ( i; 0..100 ) {
		auto gev = new GrowthEvent( population );
		population.add_event( gev );
		auto dev = new DeathEvent( gev );
		population.add_event( dev );
	}
	double t = 0;
	while ( t < 400 ) {
		t += population.time_till_next_event( gen );
		auto event = cast(Event) population.get_next_event( gen );
		density += event.execute();
		if (density == 0) {
			writeln( "Population went extinct." );
			break;
		}
		writeln( t, " ", density );
	}
}

void main() {
	import std.datetime;
	auto r = benchmark!(simulate_population)(1);
	writeln( "Simulation took (in milliseconds): ", r[0].msecs );
}
