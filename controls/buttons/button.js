SC.RenderContext.fn["button"] = function(opts) {
  // add href attr if tagName is anchor...
  var href, toolTip, classes;
  if (opts.tagName === 'a') {
    href = opts.href;
    if (!href || (href.length === 0)) href = "javascript"+":;";
    this.attr('href', href);
  }

  // If there is a toolTip set, grab it and localize if necessary.
  toolTip = opts.toolTip;
  if (SC.typeOf(toolTip) === SC.T_STRING) {
    if (opts.localize) toolTip = toolTip.loc() ;
    this.attr('title', toolTip) ;
    this.attr('alt', toolTip) ;
  }
  
  // add some standard attributes & classes.
  classes = opts._TEMPORARY_CLASS_HASH || {};
  classes.def = opts.isDefault;
  classes.cancel = opts.isCancel;
  classes.icon = opts.isIcon;
  this.attr('role', 'button')
    .setClass(classes).addClass(opts.theme);
  
  // render background slices
  if (!this.hasElement()) {
    this.push("<span class='button-left'></span>");
    this.push("<span class='button-right'></span>");
    this.push("<span class='button-middle'></span>");
  }
  
  // render inner html
  this.buttonTitle(opts);
  
  return this;
};

SC.RenderContext.fn["buttonTitle"] = function(opts) {
  var icon = opts.icon,
      image = '' ,
      title = opts.title,
      needsTitle = (!SC.none(title) && title.length>0),
      elem, htmlNode, imgTitle;
  // get the icon.  If there is an icon, then get the image and update it.
  // if there is no image element yet, create it and insert it just before
  // title.
  
  if (icon) {
    var blank = SC.BLANK_IMAGE_URL;

    if (icon.indexOf('/') >= 0) {
      image = '<img src="'+icon+'" alt="" class="icon" />';
    } else {
      image = '<img src="'+blank+'" alt="" class="'+icon+'" />';
    }
    needsTitle = YES ;
  }
  imgTitle = image + title;
  if(!this.hasElement()){
    if(opts.needsEllipsis){
      this.push('<label class="sc-button-label ellipsis">'+imgTitle+'</label>'); 
    }else{
      this.push('<label class="sc-button-label">'+imgTitle+'</label>'); 
    } 
    opts._ImageTitleCached = imgTitle;
  }else{
    elem = this.$('label');  
    if ( (htmlNode = elem[0])){
      if(needsTitle) { 
        if(opts.needsEllipsis){
          elem.addClass('ellipsis');
          if(opts._ImageTitleCached !== imgTitle) {
            opts._ImageTitleCached = imgTitle; // Update the cache
            htmlNode.innerHTML = imgTitle;
          }
        }else{
          elem.removeClass('ellipsis');
          if(opts._ImageTitleCached !== imgTitle) {
            opts._ImageTitleCached = imgTitle; // Update the cache
            htmlNode.innerHTML = imgTitle;
          }
        } 
      }
      else { htmlNode.innerHTML = ''; } 
    }
  }  
  return this ;
};