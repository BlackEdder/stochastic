import std.stdio;
import std.random;
import std.range;

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
			auto dev = new DeathEvent( population, gev );
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
	this( EventList my_population, GrowthEvent my_growth_event ) { 
		rate = 0.02;
		growth_event = my_growth_event;
		population = my_population;
	}

	override int execute() {
		population.del_event( growth_event );
		population.del_event( this );
		return -1;
	}
	private:
		GrowthEvent growth_event;
		EventList population;
}

struct GillespieState {
	real time = 0;
	BaseEvent event;
}

void simulate_population() {
	static Random gen;

	EventList population = new EventList();

	size_t density = 100;

	foreach ( i; 0..100 ) {
		auto gev = new GrowthEvent( population );
		population.add_event( gev );
		auto dev = new DeathEvent( population, gev );
		population.add_event( dev );
	}

	foreach ( state; population.simulation( gen ) ) {
		if (state[0] > 400) {
			writeln( state[0], " ", density );
			break;
		}

		auto event = cast(Event) state[1];
		density += event.execute();
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
