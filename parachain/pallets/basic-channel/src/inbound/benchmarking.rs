//! BasicInboundChannel pallet benchmarking
use super::*;

use frame_benchmarking::{account, benchmarks, impl_benchmark_test_suite, BenchmarkError};
use frame_support::traits::OnInitialize;
