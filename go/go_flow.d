#!/usr/sbin/dtrace -s
/*
 * goflow.d	Trace function flow of all go functions.
 *
 * USAGE: goflow.d -p PID [interval]
 *
 * WARNING: This traces every go function and prints details for each, and
 * as such is likely to cause significant overhead, slowing the target.
 *
 * NOTE: The output may be shuffled slightly; see comment in script.
 *
 * An optional interval can be provided, which will print a summary
 * every interval seconds.
 */

#pragma D option defaultargs
#pragma D option switchrate=10
#pragma D option quiet

/*
 * If your system supports it, add the following for correct ordering of output,
 * otherwise shuffles can occur (due to the dumping of 100ms per-CPU buffers):
 * #pragma D option temporal
 */

self int depth;

dtrace:::BEGIN
{
	printf("%3s %6s %10s %16s %s\n", "CPU", "PID", "DELTA(us)",
	    "PACKAGE", "FUNCTION");
}

pid$target:a.out::entry
/self->last == 0 && strstr(probefunc, ".") != NULL/
{
	self->last = timestamp;
}

pid$target:a.out::entry
/strstr(probefunc, ".") != NULL/
{
	this->delta = (timestamp - self->last) / 1000;
	printf("%3d %6d %10d %16s %*s-> %s\n", cpu, pid, this->delta,
	    strtok(probefunc, "."), self->depth * 2, "", strchr(probefunc, 46));
	self->depth++;
	self->last = timestamp;
}

pid$target:a.out::return
/self->last && strstr(probefunc, ".") != NULL/
{
	this->delta = (timestamp - self->last) / 1000;
	self->depth -= self->depth > 0 ? 1 : 0;
	printf("%3d %6d %10d %16s %*s<- %s\n", cpu, pid, this->delta,
	    strtok(probefunc, "."), self->depth * 2, "", strchr(probefunc, 46));
	self->last = timestamp;
}
