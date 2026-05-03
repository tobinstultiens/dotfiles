pragma Singleton
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// Wraps pactl for device listing/switching; Pipewire API for live volume/mute.
QtObject {
    id: root

    property var  sinks:         []      // [{name, description, isDefault}]
    property var  sources:       []      // [{name, description, isDefault}]
    property bool loading:       false

    property string _buf: ""

    function refresh() {
        root.loading = true
        queryProc.running = true
    }

    function setSink(name) {
        switchProc.command = ["pactl", "set-default-sink", name]
        switchProc.running = true
    }

    function setSource(name) {
        switchProc.command = ["pactl", "set-default-source", name]
        switchProc.running = true
    }

    property var _impl: Item {

        // One python3 call returns everything as a single JSON blob
        Process {
            id: queryProc
            command: [
                "python3", "-c",
                "import json,subprocess\n" +
                "sinks   = json.loads(subprocess.check_output(['pactl','--format=json','list','sinks']))\n" +
                "sources = [s for s in json.loads(subprocess.check_output(['pactl','--format=json','list','sources'])) if 'monitor' not in s['name']]\n" +
                "info    = json.loads(subprocess.check_output(['pactl','--format=json','info']))\n" +
                "print(json.dumps({'sinks':[{'name':s['name'],'description':s['description']} for s in sinks]," +
                "'sources':[{'name':s['name'],'description':s['description']} for s in sources]," +
                "'defaultSink':info['default_sink_name'],'defaultSource':info['default_source_name']}))"
            ]
            stdout: SplitParser { onRead: line => { root._buf += line } }
            onExited: {
                try {
                    var d = JSON.parse(root._buf.trim())
                    root.sinks   = d.sinks.map(s => ({
                        name: s.name, description: s.description, isDefault: s.name === d.defaultSink
                    }))
                    root.sources = d.sources.map(s => ({
                        name: s.name, description: s.description, isDefault: s.name === d.defaultSource
                    }))
                } catch(e) {}
                root._buf    = ""
                root.loading = false
            }
        }

        Process {
            id: switchProc
            onExited: queryProc.running = true
        }
    }
}
