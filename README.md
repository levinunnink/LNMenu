LNMenu
======

A NSView based replacement for NSMenu.

#### Why?

In most cases, NSMenu works great. However we ran into limitations with [Droplr](https://droplr.com) where we wanted to do more fancy stuff with our menu like showing a popover when you hovered over certain menu items, etc, similar to how Spotlight search works. This proved to be impossible with NSMenu. There just wasn't enough control. So I did the drudgery of writing a view-based replacement for NSMenu and now I'm sharing it with you.

#### Usage?

I provided a sample app that shows how to use it with a popover but feel free to hack away use it in anyway that you need. 

We used approximately this code in Droplr for Mac 2.0-3.0 to power the our NSStatusItem menu. If you come up with an improvement, submit a pull request and I'll do my best to merge it in a timley fashion.

-----

Levi Nunnink / [culturezoo.com](http://culturezoo.com) / [@a_band](http://twitter.com/a_band)
