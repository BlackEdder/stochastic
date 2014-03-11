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

alias size_t event_id;

/**
* Class implementing the gillespie algorithm
*/
final class Gillespie {
	/** 
	*	Return an infinite (lazy) array with ( time, event ) tuples
	*/
	auto simulation( ref Random gen ) {
		auto init_state = tuple( this.time_till_next_event( gen ),
				this.get_next_event( gen ) );
		return recurrence!((s,n){
				return tuple (s[n-1][0] +	this.time_till_next_event( gen ),
					this.get_next_event( gen ) );
				})( init_state );
	}

	/// Birth Death example
	unittest {
		size_t death_count = 0;
		void death( Gillespie population, ref size_t density, event_id birth_id,
				event_id death_id ) {
			death_count++;
			population.del_event( birth_id );
			population.del_event( death_id );
			density -= 1;
		}

		size_t birth_count = 0;
		void birth( Gillespie population, ref size_t density ) {
			density += 1;
			birth_count++;
			auto birth_id = population.new_event_id;
			population.add_event( birth_id, 0.03, 
					delegate () => birth( population, density ) );
			auto death_id = population.new_event_id;
			population.add_event( death_id, 0.02, 
					delegate () => death( population, density, birth_id, death_id ));
		}

		Random gen;

		auto population = new Gillespie();

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
			real exact_rate = density*(0.03 + 0.02);
			assert( 0.9999*exact_rate < population.rate  && population.rate < 1.0001*exact_rate  );

	
		}
		real ratio = (cast(real) birth_count-100)/death_count;
		assert( 0.9*ratio < 0.03/0.02  && 0.03/0.02 < 1.1*ratio  );
	}


	/// Total rate of all events combined
	@property auto rate() {
		return my_rate;
	}
	
	/// Get a new event id
	event_id new_event_id() {
		last_id += 1;
		return last_id;
	}

	/// Add a new event given an event_id, rate and event
	event_id add_event( const event_id id, real event_rate, 
			void delegate() event ) {
		rates[id] = event_rate;
		events[id] = event;
		my_rate += event_rate;
		return id;
	}

	/// Update the rate of the give event
	void update_rate( const event_id id, real new_rate ) {
		my_rate += new_rate - rates[id];
		rates[id] = new_rate;
	}

	/// Delete an event
	void del_event( const event_id id ) {
		my_rate -= rates[id];
		rates.remove( id );
		events.remove( id );
	}


	/// Return the next event
	void delegate() get_next_event( ref Random gen ) {
		assert( my_rate > 0, "Total rate is zero or smaller" ); // Assert for performance in release version
		real rnd = uniform!("()")( 0, my_rate, gen );
		real sum = 0;
		//if (rnd < 0.5*my_rate) { 
			foreach ( id, rate ; rates ) {
				sum = sum + rate;
				if (sum > rnd) {
					return events[id];
				}
			}
		assert( false, "This should not happen" );
	}

	unittest {
		import std.stdio;
		Random gen;
		auto gillespie = new Gillespie();
		auto ev1_id = gillespie.new_event_id;
		size_t call_ev1 = 0;
		auto l1 = () => (call_ev1 += 1, write("")); // Write is to force void delegate
		gillespie.add_event( ev1_id, 10.0, l1 );
		gillespie.get_next_event( gen )();
		assert( call_ev1 == 1 );

		auto ev2_id = gillespie.new_event_id;
		size_t ev2_count = 0;
		auto l2 = () => (ev2_count += 1, write(""));
		gillespie.add_event( ev2_id, 90.0, l2 );

		real t = 0;
		foreach ( i; 1..1000 ) {
			t += gillespie.time_till_next_event( gen );
			gillespie.get_next_event( gen )();
		}
		assert( ev2_count > 890 && ev2_count < 911 );
		assert( t > 9 && t < 11 );

		gillespie.update_rate( ev2_id, 20.0 );
		assert( gillespie.rate == 30.0 );
	}

	/// Time till next event
	real time_till_next_event( ref Random gen ) {
		return stochastic.random.exponential( my_rate, gen );
	}
	
	/// Number of events
	size_t length() {
		return rates.length();
	}

	private:
		real my_rate = 0;
		size_t ids;
		real[const event_id] rates;
		void delegate()[const event_id] events;

		event_id last_id = 0;
}
