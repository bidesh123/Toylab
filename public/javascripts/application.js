// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
Event.observe(window, "load", function() {
    $$("tr.core-controls").each(function(el) {
        var table = el.up("table");
        if (table) {
            Event.observe(el.up("table"), "mouseover", function() {
                el.show();
            });
            Event.observe(el.up("table"), "mouseout", function() {
                el.hide();
            });
        }
    });
    $$("input.add-aspect").each(function(el) {
        el = el.up("td.core-add-aspect");
        if (el) {
            Event.observe(el.up("table"), "mouseover", function() {
                el.show();
            });
            Event.observe(el.up("table"), "mouseout", function() {
                el.hide();
            });
        }
    });
});
