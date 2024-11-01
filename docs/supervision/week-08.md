# What have been done during the last week (7)?

This week both @emiloh and @arnenator together with Pinar had a meeting with Samsung regarding the FDP feature and some of the difficulties that we have had during the project. This gave a lot of unknown details to us which makes our lives easier in terms of the scripting for setup and benchmarks. 

Furthermore, @arnenator has looked furhter into the cachelib and have had a personal breakthrough in terms of understanding how to write to disk directly. Essentially the char file `/dev/ng1n1` is the file that is being written to, meaning that we as a developer should manage placement of items on the disk. This also means that there is potentially more work to do when adding FDP support into DuckDB, if we want to see the full benefit of talking directly with the device. @arnenator has written some of his raw observations in [this document](https://github.com/Tietgen-ITU/research-project/blob/main/docs/fdp/cachelib-fdp-impl.md).

## Questions?
___
