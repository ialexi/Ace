require("src/theme");

SC.AceTheme.renderers.Button = SC.EmptyTheme.renderers.Button.extend({
  render: function(context, firstTime) {
    // add href attr if tagName is anchor...
    var href, toolTip, classes;
    if (this.tagName === 'a') {
      href = this.href;
      if (!href || (href.length === 0)) href = "javascript"+":;";
      context.attr('href', href);
    }

    // If there is a toolTip set, grab it and localize if necessary.
    toolTip = this.toolTip;
    if (SC.typeOf(toolTip) === SC.T_STRING) {
      if (this.localize) toolTip = toolTip.loc() ;
      context.attr('title', toolTip) ;
      context.attr('alt', toolTip) ;
    }
  
    // add some standard attributes & classes.
    classes = this._TEMPORARY_CLASS_HASH || {};
    classes.def = this.isDefault;
    classes.cancel = this.isCancel;
    classes.icon = this.isIcon;
    context.attr('role', 'button')
      .setClass(classes).addClass(this.theme);
  
    // render background slices
    if (!context.hasElement()) {
      context.push("<span class='button-left'></span>");
      context.push("<span class='button-right'></span>");
      context.push("<span class='button-middle'></span>");
    }
  
    // render inner html
    this.renderTitle(context, firstTime);
  }
});