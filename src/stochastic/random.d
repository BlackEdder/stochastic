module stochastic.random;
import std.random;
import std.math;
import std.stdio;

/**
 * Generate random variable using the exponential distribution
 * Params:
 *	lambda = is the rate. 
 *	gen =	is the random number generator
 */
auto exponential( const real lambda, ref Random gen  ) {
	if (lambda<0)
		return 0;
	auto rnd = uniform!("(]")( 0.0, 1.0, gen );
	return -1.0/lambda*log( rnd );
}

unittest {
	Random gen;

	// Test lambda < 0
	assert( exponential( -1, gen ) == 0 );

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
