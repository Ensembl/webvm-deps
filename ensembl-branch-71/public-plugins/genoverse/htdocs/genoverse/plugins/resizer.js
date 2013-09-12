Genoverse.Track.on('afterInit', function () {
  if (!this.resizable) {
    return;
  }

  var track = this;
  
  this.resizer = (this.resizer || $('<div class="resizer"><div class="handle"></div></div>').appendTo(this.container).draggable({ 
    axis   : 'y',
    start  : function () { $('body').addClass('dragging'); },
    stop   : function (e, ui) {
      $('body').removeClass('dragging');
      track.resize(track.height + ui.position.top - ui.originalPosition.top, true);
      $(this).css({ top: 'auto' }); // returns the resizer to the bottom of the container - needed when the track is resized to 0
    }
  }).on('click', function () {
    if (track.fullVisibleHeight) {
      track.resize(track.fullVisibleHeight, true);
    }
  })).css({ width: this.width, left: -this.browser.left }).show();
  
  if (this.height - this.spacing === this.featureHeight) {
    this.resize(this.height + this.resizer.height());
    this.initialHeight = this.height;
  }
});

Genoverse.Track.on('afterToggleExpander', function () {
  if (this.resizer) {
    this.resizer.css('left', -this.browser.left);
    
    if (this.expander) {
      this.resizer[this.expander.filter(':visible').hide().length ? 'addClass' : 'removeClass']('shadow');
    }
  }
});

Genoverse.on('afterMove afterZoomIn afterZoomOut', function () {
  $('.resizer', this.wrapper).css('left', -this.left);
});
