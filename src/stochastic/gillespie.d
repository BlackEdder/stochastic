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

import std.random;
import std.container;
import std.exception;

private interface RateMonitor
{
	void update_rate( real old_rate, real new_rate );
}

/**
	* BaseEvent class for the gillespie algorithm
	*/
class BaseEvent
{
	/// Get the current rate
	@property auto rate() {
		return myrate;
	}

	/// Changes the current rate
	@property void rate( real new_rate ) {
		if (mymonitor)
			mymonitor.update_rate( rate, new_rate );
		myrate = new_rate;
	}

	unittest {
		BaseEvent ev = new BaseEvent;
		assert( ev.rate == 0 );
		ev.rate( 10 );
		assert( ev.rate() == 10 ); 
	}

	/**
		* Add a monitor that will be notified when the rate of the Event changes
		*/
	@property void monitor( RateMonitor rm ) {
		mymonitor = rm;
	}

	unittest {
		class MyMonitor : RateMonitor {
			double latest_rate;
			double old_rate;

			void update_rate( real rate, real new_rate ) {
				old_rate = rate;
				latest_rate = new_rate;
			}
		}

		BaseEvent ev = new BaseEvent;
		MyMonitor m = new MyMonitor;
		ev.monitor = cast(RateMonitor) m;
		ev.rate( 10 );
		assert( ev.rate == 10 );
		assert( m.latest_rate == 10 ); 
		ev.rate( 5 );
		assert( m.old_rate == 10 ); 
		assert( m.latest_rate == 5 );
	}

	private: 
		real myrate = 0;
		RateMonitor mymonitor = null;
}

/**
	* Interface for EventContainer
	*
	* Currently EventList is the only implementation of this interface
	*/
interface EventContainer
{
	@property real total_rate();
	void add_event( BaseEvent );

	/// Get time till next event
	final real time_till_next_event( ref Random gen ) {
		return stochastic.random.exponential( total_rate(), gen );
	}

	BaseEvent get_next_event( ref Random gen );
}

/**
	* Main class used for the gillespie algorithm
	*/
class EventList : EventContainer, RateMonitor {
	@property real total_rate() { return mytotal_rate; }

	/// Add an event to the eventlist
	void add_event( BaseEvent event ) {
		mytotal_rate = mytotal_rate + event.rate;
		event.monitor = this;
		container ~= [event];
	}

	unittest {
		auto el = new EventList();
		assert( el.total_rate == 0 );
		auto ev1 = new BaseEvent();
		ev1.rate = 3.0;
		el.add_event( ev1 );
		assert( el.total_rate == 3.0 );
		ev1.rate = 4.0;
		assert( el.total_rate == 4.0 );
	}

	void update_rate( real old_rate, real new_rate ) {
		mytotal_rate = mytotal_rate + (new_rate - old_rate);
	}

	/// Get the next event
	BaseEvent get_next_event( ref Random gen ) {
		assert( total_rate > 0, "Total rate is zero or smaller" ); // Assert for performance in release version
		real rnd = uniform!("()")( 0, total_rate, gen );
		real sum = 0;
		if (rnd < 0.5*total_rate) { 
			foreach ( ev; container ) {
				sum = sum + ev.rate;
				if (sum > rnd)
					return ev;
			}
		} else { // rnd so big, better start looking at the end
			rnd = total_rate - rnd;
			foreach_reverse ( ev; container ) {
				sum = sum + ev.rate;
				if (sum > rnd)
					return ev;
			}
		}

		// This should not happen and is normally caused by numerical errors.
		// Recalculate mytotal_rate should solve this problem
		mytotal_rate = 0;
		foreach( ev; container ) {
			mytotal_rate += ev.rate;
		}
		enforce( mytotal_rate > 0, "Total rate of events should be larger than zero" );
		return get_next_event( gen );
	}

	unittest {
		Random gen;
		auto el = new EventList();
		auto ev1 = new BaseEvent();
		ev1.rate = 10.0;
		el.add_event( ev1 );
		assert( el.get_next_event( gen ) == ev1 );

		auto ev2 = new BaseEvent();
		ev2.rate = 90.0;
		el.add_event( ev2 );
		size_t ev2_count = 0;
		real t = 0;
		foreach ( i; 1..1000 ) {
			t += el.time_till_next_event( gen );
			if (el.get_next_event( gen ) == ev2)
				ev2_count++;
		}
		assert( ev2_count > 890 && ev2_count < 910 );
		assert( t > 9 && t < 11 );
	}

	private:
		real mytotal_rate = 0;
		auto container = DList!BaseEvent();
}
