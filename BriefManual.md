# A very brief manual of KronoX #

This is a very brief manual of KronoX. Some day there will perhaps even be a better one.

## Hierarchical Tasks ##

A task can have any number of subtasks. This can be used to group similar tasks together. When showing statistics, some of the columns show the total time, including subtasks.

Tasks are added, edited and removed from the **File** menu.

A task can have a colour. If it doesn't, it inherits the colour from its parent. A task can have an associated comment; which can be used for address information or other references. You can also specify your normal working time for a task. Then you can see if you have been working too much or too little on a task.

## Work Periods ##

When you start recording a task, a new work period is created. When you stop recording, or switch to another task, the work period is finalised.

Recordings are started and stopped from the **File** menu, or in the toolbar. If you forgot to record a work period, you can add a new one by choosing **File -> New Work Period**. (Or delete, or edit).

Work periods have an associated date, start time, end time and duration. They also have an optional comment, where you can specify any information you want.

## Filtering/searching work periods ##

Show all work periods for a given day, week or month, by selecting from the **View** menu. Move around in time by selecting the menu items **Next**, **Previous**, **Go to Today** or **Go to Date...**. Or use the keyboard shortcuts or the toolbar.

You can also choose any date interval to show your work periods from. Or remove the date interval by clicking the **x** button next to the dates.

You can also perform more advanced searches, e.g., show all work periods for a specific task, by selecting **Find** in the **Edit** menu.

## Statistics ##

To show the statistics view, choose **View -> Statistics View** from the menu, or press the ∑ button in the toolbar. Then you see statistics for all work periods that are shown in the work period view. Change the filter and the statistics changes instantly.

You can show and hide any columns in the statistics view (and in the work period view), by selecting from the menu **View -> Columns**, or by right-clicking (or ctrl-clicking) in the table header.

## Importing and Exporting ##

You can export work periods, either to an iCal calendar, or to a comma-separated text file (or another delimiter).

Importing is not implemented yet.

## The Status Menu ##

KronoX adds a menu to the status bar in the top right. From this menu you can start and stop recordings. In the Preferences you can select how the status item should show up: as a symbol or as the name of the currently recording task. You can also select if the status item should be coloured or not.

### Preferences ###

In the Timing preferences tab, you can do the following:
  * Set your normal working time (per week, month or year). This is used in some statistics columns.
  * Set the minimum duration of a recording. All recordings shorter than this will be discarded.
  * Set the default duration of new work periods, which are created by **New Work Period**. Recall that the duration of a specific work period can always be changed.
  * Set the hour in the night when the working day ends. This is normally midnight, but if you are a late worker, you can select a later hour.
  * Set if KronoX should give a warning if the computer has been idle for some time, during a recording. This can be useful if you tend to forget to stop your recordings.

In the Viewing tab, you can do the following:
  * Set how the tables should be shown.
  * Set how the status menu item should be shown (see above).
  * Set if overlapping work periods should be shown in red.
  * Set how duration times should be shown: as hours:minutes, or as hours in decimal.

In the Updating tab, you can set if KronoX should automatically check for new updates.