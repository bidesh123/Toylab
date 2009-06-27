  Ruby on Rails | Screencasts | Download | Documentation | Weblog | Community | Source
Rails Trac
Search:

    * Login
    * Settings
    * Help/Guide
    * About Trac
    * Register

    * Wiki
    * Timeline
    * Roadmap
    * Browse Source
    * View Tickets
    * Search

    * Last Change
    * Revision Log

root/plugins/acts_as_list/README
View revision:
Revision 7443, 0.6 kB (checked in by nzkoz, 2 years ago)

Add a plugin for acts_as_list [josh]
Line	 
1 	ActsAsList
2 	==========
3 	
4 	This acts_as extension provides the capabilities for sorting and reordering a number of objects in a list. The class that has this specified needs to have a +position+ column defined as an integer on the mapped database table.
5 	
6 	
7 	Example
8 	=======
9 	
10 	  class TodoList < ActiveRecord::Base
11 	    has_many :todo_items, :order => "position"
12 	  end
13 	
14 	  class TodoItem < ActiveRecord::Base
15 	    belongs_to :todo_list
16 	    acts_as_list :scope => :todo_list
17 	  end
18 	
19 	  todo_list.first.move_to_bottom
20 	  todo_list.last.move_higher
21 	
22 	
23 	Copyright (c) 2007 David Heinemeier Hansson, released under the MIT license
Note: See TracBrowser for help on using the browser.
Download in other formats:

    * Plain Text
    * Original Format

Trac Powered

Powered by Trac 0.10.5dev
By Edgewall Software.

Visit the Ruby on Rails project at
http://rubyonrails.org/
