notepad-panel#notepad.panel.dockright(class="{opened: opened}")
    ul.nav.tabs.nogrow.nb
        li(onclick="{changeTab('notepadlocal')}" class="{active: tab === 'notepadlocal'}")
            svg.feather
                use(xlink:href="data/icons.svg#edit")
            span {voc.local}
        li(onclick="{changeTab('notepadglobal')}" class="{active: tab === 'notepadglobal'}")
            svg.feather
                use(xlink:href="data/icons.svg#clipboard")
            span {voc.global}
        li(onclick="{changeTab('helppages')}" class="{active: tab === 'helppages'}")
            svg.feather
                use(xlink:href="data/icons.svg#life-buoy")
            span {voc.helppages}
    div
        div(show="{tab === 'notepadlocal'}")
            .aCodeEditor(ref="notepadlocal")
        div(show="{tab === 'notepadglobal'}")
            .aCodeEditor(ref="notepadglobal")
        div(show="{tab === 'helppages'}")
            iframe(src="http://localhost:{server.address().port}/{getIfDarkTheme()? '?darkTheme=yep' : ''}" ref="helpIframe" nwdisable nwfaketop)
            button.aHomeButton(title="{voc.backToHome}" onclick="{backToHome}")
                svg.feather
                    use(xlink:href="data/icons.svg#home")

    button.vertical.dockleft(onclick="{notepadToggle}")
        svg.feather
            use(xlink:href="data/icons.svg#{opened? 'chevron-right' : 'chevron-left'}")
    script.
        const glob = require('./data/node_requires/glob');
        const hotkey = require('./data/node_requires/hotkeys')(document);
        this.opened = false;
        this.namespace = 'notepad';
        this.mixin(window.riotVoc);
        this.notepadToggle = function notepadToggle() {
            this.opened = !this.opened;
        };

        hotkey.on('F1', () => {
            this.opened = true;
            this.tab = 'helppages';
            this.update();
        });

        this.tab = 'notepadlocal';
        this.changeTab = tab => () => {
            this.tab = tab;
        };
        this.on('update', () => {
            setTimeout(() => {
                if (this.tab && this.refs[this.tab] && this.refs[this.tab].codeEditor) {
                    this.refs[this.tab].codeEditor.layout();
                    this.refs[this.tab].codeEditor.focus();
                }
            }, 0);
        });
        const updateEditorSize = () => {
            if (this.tab && this.refs[this.tab]) {
                this.refs[this.tab].codeEditor.layout();
            }
        };
        window.addEventListener('resize', updateEditorSize);
        this.on('unmount', () => {
            window.removeEventListener('resize', updateEditorSize);
        });

        this.getIfDarkTheme = () =>
            localStorage.UItheme === 'Night' || localStorage.UItheme === 'Horizon';

        this.backToHome = () => {
            this.refs.helpIframe.contentWindow.location = `http://localhost:${fileServer.address().port}/`;
        };

        this.on('update', () => {
            this.notepadlocal.setValue(global.currentProject.notes || '');
        });

        this.on('mount', () => {
            setTimeout(() => {
                this.notepadlocal = window.setupCodeEditor(this.refs.notepadlocal, {
                    language: 'typescript'
                });
                this.notepadglobal = window.setupCodeEditor(this.refs.notepadglobal, {
                    language: 'typescript'
                });

                this.notepadlocal.onDidChangeModelContent(() => {
                    global.currentProject.notes = this.notepadlocal.getValue();
                    glob.modified = true;
                });
                this.notepadglobal.onDidChangeModelContent(() => {
                    localStorage.notes = this.notepadglobal.getValue();
                });
                this.notepadglobal.setValue(localStorage.notes);
            }, 0);
        });
        this.on('unmount', () => {
            // Manually destroy the editors to free up the memory
            this.notepadlocal.dispose();
            this.notepadglobal.dispose();
        });

        const fileServerSettings = {
            public: 'data/docs/',
            cleanUrls: true
        };
        const handler = require('serve-handler');
        fileServer = require('http').createServer((request, response) => {
            return handler(request, response, fileServerSettings);
        });
        fileServer.listen(0, () => {
            console.info(`[ct.docs] Running docs server at http://localhost:${fileServer.address().port}`);
        });
        this.server = fileServer;

        var openDocs = e => {
            this.changeTab('helppages')();
            this.refs.helpIframe.contentWindow.location = `http://localhost:${fileServer.address().port}${e.path || '/'}`;
            this.opened = true;
            this.update();
        };
        window.signals.on('openDocs', openDocs);
        this.on('unmount', () => {
            window.signals.off('openDocs', openDocs);
        });