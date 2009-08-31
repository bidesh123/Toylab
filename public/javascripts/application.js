function installAutocomplete(el, url) {
  var inplaceForm = $(el.id + "-inplaceeditor");
  var inplaceFields = inplaceForm.select("input");
  var inplaceField = inplaceFields[0];
  var update = inplaceForm.up("th").down(".auto_complete");
  new Ajax.Autocompleter(inplaceField, update, url, {method:'get', paramName: 'q'});
};

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

    $$(".editor.in-place-edit.card-kind").each(function(el) {
        Event.observe(el, "click", function() {
            installAutocomplete.delay(0.1, el, '/cards/auto/kind');
        });
    });
});
