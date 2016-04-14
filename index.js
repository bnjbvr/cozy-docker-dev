#!/usr/bin/env node

var JsonClient = require('request-json').JsonClient;
var path = require('path');
var fs = require('fs');
var spawn = require('child_process').spawn;

var PROXY_URL = 'http://localhost:9104';
var DATA_SYSTEM_URL = 'http://localhost:9101';

var SSH_PORT = 2222;

var proxyClient = new JsonClient(PROXY_URL);
var dataSystemClient = new JsonClient(DATA_SYSTEM_URL);

function makeManifest(packagePath, port) {
    var manifest = require(packagePath);
    return {
        permissions: manifest['cozy-permissions'],
        name: manifest.name.replace('cozy-', ''),
        slug: manifest.slug || manifest.name,
        displayName: manifest['cozy-displayName'] || manifest.name,
        state: 'installed',
        autostop: false,
        password: 'dev',
        docType: 'Application',
        type: manifest['cozy-type'] || {},
        port: port || 9000
    }
}

function addInDatabase(manifest, cb) {
    dataSystemClient.post('/data', manifest, function(err, res, body) {
        console.log('Add in database:\n\tError: ', err, '\n\tBody: ', body);
        if (cb)
            cb(err);
    });
}

function removeFromDatabase(manifest, cb) {
    var param = { key: manifest.slug };
    dataSystemClient.post('request/application/byslug', param, function(err, res, body) {
        if (err) {
            console.error('removeFromDatabase error:', err);
            return;
        }

        if (!body || !body.length || !body[0].value) {
            console.error('removeFromDatabase: unable to find the app');
            return;
        }

        var app = body[0].value;
        dataSystemClient.del('data/' + app._id, function(err, res, body) {
            console.log('removeFromDatabase:\n\tError:', err, '\n\tBody:', body);
            cb(err);
        });
    });
}

function resetProxy(cb) {
    proxyClient.get('routes/reset', function(err, res, body) {
        console.log('Reset proxy:\n\tError: ', err, '\n\tBody: ', body);
        if (cb)
            cb(err);
    });
}

function addPortForwarding(port, cb) {
    var command = 'ssh';
    var args = ['-N', '-p', SSH_PORT, '-R', port + ':localhost:' + port, 'root@localhost'];

    console.log('Running', command, args, '...');
    console.log('Press Ctrl+C to stop.');
    var child = spawn(command, args);

    child.stdout.on('data', function(data) { console.log(data.toString()); })
    child.stderr.on('data', function(data) { console.log('stderr', data.toString()); })
}

var argv = process.argv;
var argc = argv.length; // lol
if (argc < 4) {
    console.log('usage:', argv[1], ' path/to/package.json port');
    process.exit();
}

var packagePath = argv[2];
var port = parseInt(argv[3]);

var manifest = makeManifest(packagePath, port);

addInDatabase(manifest, function(err) {
    if (err)
        return;
    resetProxy(function (err) {
        if (err)
            return;
        addPortForwarding(port);
    });
});

process.on('SIGINT', function() {
    console.log('\nCleaning properly...');
    removeFromDatabase(manifest, function(err) {
        if (err) {
            console.error("Error when cleaning:", err);
        } else {
            console.log('Exiting, have a nice day!');
        }
    });
});
