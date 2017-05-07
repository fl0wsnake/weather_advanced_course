'use strict';

require("../node_modules/semantic-ui-css/semantic.min.css")

var Elm = require('./app.elm');
var mountNode = document.getElementById('main');

var app = Elm.Main.embed(mountNode);