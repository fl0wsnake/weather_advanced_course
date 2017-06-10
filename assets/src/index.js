'use strict';

require("../node_modules/semantic-ui-css/semantic.min.css")

let Elm = require('./app.elm')
let mountNode = document.getElementById('main')

let app = Elm.Main.embed(mountNode)