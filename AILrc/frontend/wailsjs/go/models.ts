export namespace main {
	
	export class AppConfig {
	    fontSize: number;
	    fontColor: string;
	    strokeColor: string;
	    bgOpacity: number;
	    textOpacity: number;
	    windowWidth: number;
	
	    static createFrom(source: any = {}) {
	        return new AppConfig(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.fontSize = source["fontSize"];
	        this.fontColor = source["fontColor"];
	        this.strokeColor = source["strokeColor"];
	        this.bgOpacity = source["bgOpacity"];
	        this.textOpacity = source["textOpacity"];
	        this.windowWidth = source["windowWidth"];
	    }
	}
	export class LyricLine {
	    time: number;
	    mainText: string;
	    subText: string;
	
	    static createFrom(source: any = {}) {
	        return new LyricLine(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.time = source["time"];
	        this.mainText = source["mainText"];
	        this.subText = source["subText"];
	    }
	}
	export class MusicInfo {
	    FileName: string;
	    TrackNumber: number;
	
	    static createFrom(source: any = {}) {
	        return new MusicInfo(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.FileName = source["FileName"];
	        this.TrackNumber = source["TrackNumber"];
	    }
	}
	export class PlayerState {
	    Position: number;
	    State: number;
	
	    static createFrom(source: any = {}) {
	        return new PlayerState(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.Position = source["Position"];
	        this.State = source["State"];
	    }
	}

}

