/*
	 -------------------------------------------------------------------

	 Copyright (C) 2014, Edwin van Leeuwen

	 This file is part of stochastic library for d.

	 Stochastic is free software; you can redistribute it and/or modify
	 it under the terms of the GNU General Public License as published by
	 the Free Software Foundation; either version 3 of the License, or
	 (at your option) any later version.

	 Stocahstic is distributed in the hope that it will be useful,
	 but WITHOUT ANY WARRANTY; without even the implied warranty of
	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	 GNU General Public License for more details.

	 You should have received a copy of the GNU General Public License
	 along with stochastic. If not, see <http://www.gnu.org/licenses/>.

	 -------------------------------------------------------------------
	 */

/**
	Implement the Gillespie algorithm
	*/
module stochastic.gillespie;

import stochastic.random;

import std.random;
import std.range;
import std.container;
import std.exception;

alias size_t EventId;

/**
* Class implementing the gillespie algorithm
*/
final class Gillespie( T ) {
	/** 
	*	Return an infinite (lazy) array with ( time, event ) tuples
	*/
	auto simulation( ref Random gen ) {
		auto initState = tuple( this.timeTillNextEvent( gen ),
				this.getNextEvent( gen ) );
		return recurrence!((s,n){
				return tuple (s[n-1][0] +	this.timeTillNextEvent( gen ),
					this.getNextEvent( gen ) );
				})( initState );
	}


	/// Total rate of all events combined
	@property auto rate() {
		return myRate;
	}
	
	/// Get a new event id
	EventId newEventId() {
		lastId += 1;
		return lastId;
	}

	/// Add a new event given an EventId, rate and event
	EventId addEvent( const EventId id, real eventRate, 
			T event ) {
		rates[id] = eventRate;
		events[id] = event;
		myRate += eventRate;
		return id;
	}

	/// Update the rate of the give event
	void updateRate( const EventId id, real newRate ) {
		myRate += newRate - rates[id];
		rates[id] = newRate;
	}

	/// Delete an event
	void delEvent( const EventId id ) {
		myRate -= rates[id];
		rates.remove( id );
		events.remove( id );
	}


	/// Return the next event
	T getNextEvent( ref Random gen ) {
		assert( myRate > 0, "Total rate is zero or smaller" ); // Assert for performance in release version
		real rnd = uniform!("()")( 0, myRate, gen );
		real sum = 0;
		//if (rnd < 0.5*myRate) { 
			foreach ( id, rate ; rates ) {
				sum = sum + rate;
				if (sum > rnd) {
					return events[id];
				}
			}
		assert( false, "This should not happen" );
	}

	/// Time till next event
	real timeTillNextEvent( ref Random gen ) {
		return stochastic.random.exponential( myRate, gen );
	}
	
	/// Number of events
	size_t length() {
		return rates.length();
	}

	private:
		real myRate = 0;
		size_t ids;
		real[const EventId] rates;
		T[const EventId] events;

		EventId lastId = 0;
}

version(unittest) {
	import std.stdio;
}

/// Birth Death example
unittest {
	size_t deathCount = 0;
	void death(T)( Gillespie!(T) population, ref size_t density, EventId birthId,
			EventId deathId ) {
		deathCount++;
		population.delEvent( birthId );
		population.delEvent( deathId );
		density -= 1;
	}

	size_t birthCount = 0;
	void birth(T)( Gillespie!(T) population, ref size_t density ) {
		density += 1;
		birthCount++;
		auto birthId = population.newEventId;
		population.addEvent( birthId, 0.03, 
				delegate () => birth( population, density ) );
		auto deathId = population.newEventId;
		population.addEvent( deathId, 0.02, 
				delegate () => death( population, density, birthId, deathId ));
	}

	Random gen;

	auto population = new Gillespie!(void delegate())();

	size_t density = 0;

	foreach ( i; 0..100 ) {
		birth( population, density ); // Initial population
	}

	foreach ( state; population.simulation( gen ) ) {
		if (state[0] > 100) { // Stop after time > 100
			break;
		}

		state[1](); // Execute event

		if (density == 0) {
			break;
		}
		assert( population.length == 2*density ); // Birth and death event for each individual
		real exactRate = density*(0.03 + 0.02);
		assert( 0.9999*exactRate < population.rate  && population.rate < 1.0001*exactRate  );


	}
	real ratio = (cast(real) birthCount-100)/deathCount;
	assert( 0.9*ratio < 0.03/0.02  && 0.03/0.02 < 1.1*ratio  );
}

unittest {
	Random gen;
	auto gillespie = new Gillespie!(void delegate())();
	auto ev1Id = gillespie.newEventId;
	size_t callEv1 = 0;
	auto l1 = () => (callEv1 += 1, write("")); // Write is to force void delegate
	gillespie.addEvent( ev1Id, 10.0, l1 );
	gillespie.getNextEvent( gen )();
	assert( callEv1 == 1 );

	auto ev2Id = gillespie.newEventId;
	size_t ev2Count = 0;
	auto l2 = () => (ev2Count += 1, write(""));
	gillespie.addEvent( ev2Id, 90.0, l2 );

	real t = 0;
	foreach ( i; 1..1000 ) {
		t += gillespie.timeTillNextEvent( gen );
		gillespie.getNextEvent( gen )();
	}
	assert( ev2Count > 890 && ev2Count < 911 );
	assert( t > 9 && t < 11 );

	gillespie.updateRate( ev2Id, 20.0 );
	assert( gillespie.rate == 30.0 );
}
