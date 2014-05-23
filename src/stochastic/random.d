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

module stochastic.random;
public import std.random;
import std.math;
import std.stdio;
import std.exception;

/**
 * Generate random variable using the exponential distribution
 * Params:
 *	lambda = is the rate. 
 *	gen =	is the random number generator
 */
auto exponential( const real lambda, ref Random gen  ) {
	enforce(lambda >= 0, "Rate needs to be equal to or larger than 0");
	auto rnd = uniform!("(]")( 0.0, 1.0, gen );
	return -1.0/lambda*log( rnd );
}

unittest {
	Random gen;

	// Test large number of results
	double cdf( double x, double lambda ) {
		return 1-exp( -lambda*x );
	}
	double sum = 0;
	double cdf_test = 0;
	for (int i = 0; i < 10000; i++) {
		double rexp = exponential( 10.0, gen );
		assert( rexp > 0 );
		sum = sum + rexp;
		if (rexp < 0.02)
			cdf_test++;
	}
	assert( sum > 990.0 && sum < 1010.0 );
	double real_cdf = 10000.0*cdf( 0.02, 10.0 );
	assert( cdf_test > 0.95*real_cdf && cdf_test < 1.05*real_cdf );
}

/**
 * Generate random variable using the normal distribution
 * Params:
 *	mu = is the mean. 
 *  sd = is the standard deviation
 *	gen =	is the random number generator
 */
auto normal( const real mu, const real sd, ref Random gen  ) {
	static bool generate = true;
	static real rnd2;

	if (sd<0)
		return 0;
	if (generate) {
		auto u = uniform!("()")( 0.0, 1.0, gen );
		auto v = uniform!("()")( 0.0, 1.0, gen );
		auto exp1 = sqrt(-2.0*log(u));
		auto exp2 = 2*v*PI;
		auto rnd1 = exp1*cos(exp2); 
		rnd2 = exp1*sin(exp2); // Cache the second result for performance
		generate = false;
		return mu+sd*rnd1;
	} else {
		generate = true;
		return mu+sd*rnd2;
	}
}

unittest {
	Random gen;

	// Standard deviation should be above 0
	assert( normal( 0, -1, gen ) == 0 );

	double sum = 0;
	double cdf_test = 0;
	for (int i = 0; i < 10000; i++) {
		double rnorm = normal( 2.0, 0.5, gen );
		sum = sum + rnorm;
		if (rnorm < 2.0-1.96*0.5)
			cdf_test++;
	}
	sum = sum/10000.0;
	assert( sum > 1.99 && sum < 2.01 );
	cdf_test = cdf_test/10000.0;
	assert( cdf_test > 0.024 && cdf_test < 0.026 );

}

private int factorial(int i)
{ if (i == 0)
    return 1;
  else
    return i * factorial(i - 1);
}

/**
 * Generate random variable using the poisson distribution
 * Params:
 *	lambda = is the rate. 
 *	gen =	is the random number generator
 */
size_t poisson( const real lambda, ref Random gen  ) {
	// Implementation based on Knuth
	enforce(lambda>=0, "Rate needs to be equal to or larger than 0");
	double p = 1;
	double l = exp( -lambda );
	size_t k = 0;
	while (p>l) {
		k++;
		p *= uniform!("[]")(0.0, 1.0, gen );
	}
	return k-1;
}

unittest {
	Random gen;

	// Test large number of results
	double cdf( double x, double lambda ) {
		double sum = 0;
		for (int i = 0; i <= floor(x); ++i) {
			sum += pow(lambda, i)/factorial( i );
		}
		return exp(-lambda)*sum;
	}
	double sum = 0;
	double cdf_test = 0;
	for (int i = 0; i < 10000; i++) {
		double rpois = poisson( 5.0, gen );
		assert( rpois >= 0 );
		sum = sum + rpois;
		if (rpois <= 2)
			cdf_test++;
	}
	assert( sum > 49000 && sum < 51000 );
	double real_cdf = 10000*cdf( 2.5, 5.0 );
	assert( cdf_test > 0.95*real_cdf && cdf_test < 1.05*real_cdf );
}

