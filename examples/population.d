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

struct GillespieState {
	real time = 0;
	BaseEvent event;
	EventList gillespie;
	Random gen;
}

void simulate_population() {
	static Random gen;

	EventList population = new EventList();

	size_t density = 100;

	foreach ( i; 0..100 ) {
		auto gev = new GrowthEvent( population );
		population.add_event( gev );
		auto dev = new DeathEvent( gev );
		population.add_event( dev );
	}

	GillespieState init_state;
	init_state.gillespie = population;
	init_state.time = population.time_till_next_event( init_state.gen );
	init_state.event = population.get_next_event( init_state.gen );
	init_state.gen = gen;
	auto simulation = recurrence!((s,n){
			auto state = s[n];
			state.time += state.gillespie.time_till_next_event( state.gen );
			state.event = state.gillespie.get_next_event( gen );
			return state;
		})( init_state );

	foreach ( state; simulation ) {
		if (state.time > 400) {
			writeln( state.time, " ", density );
			break;
		}

		auto event = cast(Event) state.event;
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
