/* Simple Grid Scripts tables with fixed First Row and Line */

// scrolls first line and row with body
// div is this
// row is id of row Ex: g_fr
// line is id of line Ex: g_fl
function g_scroll(div, line, row) {
  document.getElementById(line).style.left = - div.scrollLeft + 'px';
  document.getElementById(row).style.top = - div.scrollTop + 'px';
}

// adjusts width of rows
// bli is the block div
// fri is the first row div
// fli is the first line div
// bdi is the body div
function g_adjust(bli, fri, fli, bdi) {
  var frw = document.getElementById(fri).offsetWidth;
  var frw2 = document.getElementById(bli).offsetWidth;
  if ( frw2 > frw ) {
    frw = frw2 + "px"
  } else {
    frw = frw + "px";
  }

  document.getElementById(fri).style.width = frw;
  document.getElementById(bli).style.width = frw;

  var fl = document.getElementById(fli);
  fl.children[0].style.width = frw;

  var bd = document.getElementById(bdi);
  bd.children[0].style.width = frw;

  for (var i = 1; i < fl.children.length; i++) {
    s1 = fl.children[i].offsetWidth;
    s2 = bd.children[i].offsetWidth;
    if (s1 > s2) {
      bd.children[i].style.width = s1 + "px"
    } else {
      fl.children[i].style.width = s2 + "px"
    }
  }
}

// Toggle visibility of table
function toggleDivToFieldset(divId, fsClass) {
  if (~fsClass.indexOf("collapsed")) {
    document.getElementById(divId).style.visibility='hidden';
    document.getElementById(divId).style.position='fixed';
  } else {
    document.getElementById(divId).style.visibility='';
    document.getElementById(divId).style.position='relative';
    document.getElementById(divId).children[1].style.left='0px';
  }
}
