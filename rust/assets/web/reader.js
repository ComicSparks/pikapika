const Reader = {
    template: `
        <div style="min-height: 100vh; background: black;">
            <div @click="switchFullScreen" :style="'width: '+divWidth + 'vw; margin: auto;'">
                <img v-for="picture in images" :src="'downloadResource/'+picture.localPath" style="
                  width: 100%;
                "/>
            </div>
            <div v-if="!fullScreen" style="
                position: fixed;
                top: 0;
                width: 100%;
                background: #00000099;
                color:white;
                line-height: 1.4em;
                display: flex;
                 ">
                <span  @click="back" style="flex-grow: 0; flex-shrink: 0">
                  返回
                </span>
                <span style="flex-grow: 0; flex-shrink: 0">&nbsp;&nbsp;&nbsp;</span>
                <div style="flex-grow: 1; flex-shrink: 1; overflow: hidden; text-overflow: ellipsis; height: 1.4em; text-align: right">
                   <span v-if="chapterInfo && chapterInfo.title">
                     {{chapterInfo.title}}
                   </span>
                </div>
            </div>
            <div v-if="!fullScreen" style="
                position: fixed;
                bottom: 0;
                width: 100%;
                background: #00000099;
                color:white;
                line-height: 1.4em;
                display: flex;
                 ">
                <span @click="decreaseWidth" style="flex-grow: 0; flex-shrink: 0">
                  -缩放
                </span>
                <span style="flex-grow: 0; flex-shrink: 0">&nbsp;&nbsp;&nbsp;</span>
                <span @click="increaseWidth" style="flex-grow: 0; flex-shrink: 0">
                  +缩放
                </span>
                <div style="flex-grow: 1; flex-shrink: 1; overflow: hidden; text-overflow: ellipsis; height: 1.4em; text-align: right">
                   &nbsp;
                </div>
                <span style="flex-grow: 0; flex-shrink: 0">&nbsp;&nbsp;&nbsp;</span>
                <span @click="next" style="flex-grow: 0; flex-shrink: 0">
                  下一章
                </span>
            </div>
        </div>
      `,
    setup() {
        const images = Vue.ref([]);
        const chapterInfo = Vue.ref({});
        const fullScreen = Vue.ref(false);
        const nextChapter = Vue.ref({});
        const route = VueRouter.useRoute();
        const divWidth = Vue.ref(100);

        function load(id) {
            axios.get('/chapter/images/' + id)
                .then(response => {
                    images.value = response.data;
                })
                .catch(error => {
                    console.log(error);
                });
            axios.get('/chapter/info/' + id)
                .then(response => {
                    chapterInfo.value = response.data;
                    axios.get('/next/chapter/' + response.data.comicId + "/" + response.data.epOrder)
                        .then(response => {
                            nextChapter.value = response.data;
                        })
                        .catch(error => {
                            console.log(error);
                        });
                })
                .catch(error => {
                    console.log(error);
                });
        }

        function reload(id) {
            images.value = [];
            chapterInfo.value = [];
            nextChapter.value = [];
            load(id)
        }

        Vue.onMounted(() => {
            load(route.params.id);
            Vue.watch(() => route.params.id, (newValue, oldValue) => {
                reload(newValue)
            });
            try {
                var dw = localStorage.getItem('divWidth') ? parseInt(localStorage.getItem('divWidth')) : 100;
                divWidth.value = dw;
            } catch (e) {
                console.log(e);
            }
        });
        return {
            images,
            fullScreen,
            chapterInfo,
            nextChapter,
            divWidth,
        };
    },
    methods: {
        switchFullScreen() {
            this.fullScreen = !this.fullScreen;
        },
        back() {
            this.$router.go(-1);
        },
        next() {
            if (this.nextChapter && this.nextChapter.id) {
                this.$router.push({
                    path: "/reader/" + this.nextChapter.id,
                    replace: true,
                })
            }
        },
        increaseWidth() {
            if (this.divWidth < 100) {
                this.divWidth += 10;
                if (this.divWidth > 100) {
                    this.divWidth = 100;
                }
                this.saveWidth();
            }
        },
        decreaseWidth() {
            if (this.divWidth > 10) {
                this.divWidth -= 10;
                if (this.divWidth < 10) {
                    this.divWidth = 10;
                }
                this.saveWidth();
            }
        },
        saveWidth() {
            try {
                localStorage.setItem('divWidth', this.divWidth);
            } catch (e) {
                console.log(e);
            }
        },
    },
}
app.component('Reader', Reader);
