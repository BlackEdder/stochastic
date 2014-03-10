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

class Gillespie {
	import std.stdio;

	@property auto rate() {
		return my_rate;
	}

	final event_id new_event_id() {
		last_id += 1;
		return last_id;
	}

	final event_id add_event( event_id id, real event_rate, void delegate() event ) {
		debug writeln( "added ID: ", id, " with rate: ", event_rate );
		rates[id] = event_rate;
		events[id] = event;
		my_rate += event_rate;
		return id;
	}

	final void update_rate( event_id id, real new_rate ) {
		debug writeln( "updated ID: ", id, " with rate: ", new_rate );
		my_rate += new_rate - rates[id];
		rates[id] = new_rate;
	}

	final void del_event( event_id id ) {
		debug writeln( "deleted ID: ", id, " with rate: ", rates[id] );
		my_rate -= rates[id];
		rates.remove( id );
		events.remove( id );
	}

	final void delegate() get_next_event( ref Random gen ) {
		assert( my_rate > 0, "Total rate is zero or smaller" ); // Assert for performance in release version
		real rnd = uniform!("()")( 0, my_rate, gen );
		real sum = 0;
		//if (rnd < 0.5*my_rate) { 
			foreach ( id, rate ; rates ) {
				sum = sum + rate;
				if (sum > rnd) {
					debug writeln( "Picked: ", id, " ", rnd, " ", sum, " ", my_rate );
					return events[id];
				}
			}
		assert( false, "This should not happen" );
	}

	final auto simulation( ref Random gen ) {
		auto init_state = tuple( this.time_till_next_event( gen ),
				this.get_next_event( gen ) );
		return recurrence!((s,n){
				return tuple (s[n-1][0] +	this.time_till_next_event( gen ),
					this.get_next_event( gen ) );
				})( init_state );
	}

	unittest {
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
	}



	final real time_till_next_event( ref Random gen ) {
		return stochastic.random.exponential( my_rate, gen );
	}

	final size_t length() {
		return rates.length();
	}

	private:
		real my_rate = 0;
		size_t ids;
		real[event_id] rates;
		void delegate()[event_id] events;

		event_id last_id = 0;
}
