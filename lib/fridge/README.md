### The Fridge List view

This directory contains code for displaying the fridges and wines within the fridges.

The view structure is the following:

entrypoint: view.dart (contains the fridges and unallocated view navigation)

* fridges.dart (list of fridges)
  * rows.dart (list of rows in a fridge)
    * bottles.dart (list of bottles in a row)
* unallocated.dart (list of bottles that have not been allocated)
