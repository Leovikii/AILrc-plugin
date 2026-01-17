package main

import (
	"bufio"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/saintfish/chardet"
	"golang.org/x/text/encoding/japanese"
	"golang.org/x/text/encoding/simplifiedchinese"
	"golang.org/x/text/encoding/traditionalchinese"
	"golang.org/x/text/transform"
)

type LyricLine struct {
	Time     int64  `json:"time"`
	MainText string `json:"mainText"`
	SubText  string `json:"subText"`
}

type cacheEntry struct {
	ModTime time.Time
	Lyrics  []LyricLine
}

var (
	lrcRegex       = regexp.MustCompile(`\[(\d{1,2}):(\d{1,2})(?:\.(\d{1,3}))?\]`)
	srtVttRegex    = regexp.MustCompile(`(?:(\d{1,2}):)?(\d{1,2}):(\d{1,2})(?:[.,](\d{1,3}))?`)
	bracketRegex   = regexp.MustCompile(`^(.*?)\s*[(（【\[](.*?)[)）】\]]\s*$`)
	delimiterRegex = regexp.MustCompile(`^(.*?)\s*[/|]\s*(.*?)$`)
	lyricCache     = make(map[string]cacheEntry)
)

func LoadLyrics(pathStr string) []LyricLine {
	if pathStr == "" {
		return nil
	}

	lrcPath := findLyricFile(pathStr)
	if lrcPath == "" {
		return nil
	}

	info, err := os.Stat(lrcPath)
	if err != nil {
		return nil
	}

	if entry, ok := lyricCache[lrcPath]; ok {
		if entry.ModTime.Equal(info.ModTime()) {
			return entry.Lyrics
		}
	}

	content, err := os.ReadFile(lrcPath)
	if err != nil {
		return nil
	}

	ext := strings.ToLower(filepath.Ext(lrcPath))
	if strings.HasSuffix(strings.ToLower(lrcPath), ".wav.vtt") || strings.HasSuffix(strings.ToLower(lrcPath), ".wav.lrc") {
		// handle compound extensions logic if needed specifically, but generic parse works
	}

	lyrics := parseLyrics(content, ext)

	lyricCache[lrcPath] = cacheEntry{
		ModTime: info.ModTime(),
		Lyrics:  lyrics,
	}

	return lyrics
}

func findLyricFile(audioPath string) string {
	exts := []string{".lrc", ".srt", ".vtt", ".txt"}

	baseWithoutExt := audioPath
	ext := filepath.Ext(audioPath)
	if ext != "" {
		baseWithoutExt = strings.TrimSuffix(audioPath, ext)
	}

	searchPaths := []string{
		baseWithoutExt,
		audioPath,
	}

	for _, basePath := range searchPaths {
		for _, e := range exts {
			path := basePath + e
			if _, err := os.Stat(path); err == nil {
				return path
			}
		}
	}

	return ""
}

func parseLyrics(content []byte, ext string) []LyricLine {
	utf8Content := convertToUTF8(content)

	if strings.Contains(ext, "srt") || strings.Contains(ext, "vtt") {
		return parseSrtVtt(utf8Content)
	}
	return parseLrc(utf8Content)
}

func parseLrc(content string) []LyricLine {
	var rawLines []tempLine
	scanner := bufio.NewScanner(strings.NewReader(content))

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		matches := lrcRegex.FindAllStringSubmatchIndex(line, -1)
		if len(matches) == 0 {
			continue
		}

		text := strings.TrimSpace(line[matches[len(matches)-1][1]:])

		for _, match := range matches {
			min, _ := strconv.Atoi(line[match[2]:match[3]])
			sec, _ := strconv.Atoi(line[match[4]:match[5]])
			ms := 0
			if match[6] != -1 {
				msStr := line[match[6]:match[7]]
				if len(msStr) == 2 {
					msStr += "0"
				} else if len(msStr) == 1 {
					msStr += "00"
				}
				ms, _ = strconv.Atoi(msStr)
			}

			rawLines = append(rawLines, tempLine{
				Time: int64(min*60000 + sec*1000 + ms),
				Text: text,
			})
		}
	}

	return processLines(rawLines)
}

func parseSrtVtt(content string) []LyricLine {
	var rawLines []tempLine
	scanner := bufio.NewScanner(strings.NewReader(content))

	var currentTime int64 = -1
	var textBuilder strings.Builder

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		if line == "WEBVTT" || strings.HasPrefix(line, "NOTE") {
			continue
		}

		if line == "" {
			if currentTime != -1 && textBuilder.Len() > 0 {
				rawLines = append(rawLines, tempLine{
					Time: currentTime,
					Text: textBuilder.String(),
				})
				currentTime = -1
				textBuilder.Reset()
			}
			continue
		}

		if matches := srtVttRegex.FindStringSubmatch(line); len(matches) > 0 {
			if currentTime != -1 && textBuilder.Len() > 0 {
				rawLines = append(rawLines, tempLine{
					Time: currentTime,
					Text: textBuilder.String(),
				})
				textBuilder.Reset()
			}

			h := 0
			m := 0
			s := 0
			ms := 0

			if matches[1] != "" {
				h, _ = strconv.Atoi(matches[1])
				m, _ = strconv.Atoi(matches[2])
				s, _ = strconv.Atoi(matches[3])
				if len(matches) > 4 && matches[4] != "" {
					msStr := matches[4]
					for len(msStr) < 3 {
						msStr += "0"
					}
					ms, _ = strconv.Atoi(msStr)
				}
			} else {
				m, _ = strconv.Atoi(matches[2])
				s, _ = strconv.Atoi(matches[3])
				if len(matches) > 4 && matches[4] != "" {
					msStr := matches[4]
					for len(msStr) < 3 {
						msStr += "0"
					}
					ms, _ = strconv.Atoi(msStr)
				}
			}

			currentTime = int64(h*3600000 + m*60000 + s*1000 + ms)
		} else if currentTime != -1 {
			if strings.Contains(line, "-->") {
				continue
			}
			if _, err := strconv.Atoi(line); err == nil {
				continue
			}
			if textBuilder.Len() > 0 {
				textBuilder.WriteString("\n")
			}
			textBuilder.WriteString(line)
		}
	}

	if currentTime != -1 && textBuilder.Len() > 0 {
		rawLines = append(rawLines, tempLine{
			Time: currentTime,
			Text: textBuilder.String(),
		})
	}

	return processLines(rawLines)
}

type tempLine struct {
	Time int64
	Text string
}

func abs(x int64) int64 {
	if x < 0 {
		return -x
	}
	return x
}

func processLines(rawLines []tempLine) []LyricLine {
	sort.SliceStable(rawLines, func(i, j int) bool {
		return rawLines[i].Time < rawLines[j].Time
	})

	var lyrics []LyricLine
	const MergeThreshold = 200

	for i := 0; i < len(rawLines); i++ {
		curr := rawLines[i]

		if i > 0 && abs(curr.Time-rawLines[i-1].Time) < MergeThreshold {
			lastIdx := len(lyrics) - 1
			if lastIdx >= 0 {
				if lyrics[lastIdx].MainText == curr.Text || lyrics[lastIdx].SubText == curr.Text {
					continue
				}
				if lyrics[lastIdx].SubText == "" {
					lyrics[lastIdx].SubText = curr.Text
				} else {
					lyrics[lastIdx].SubText += "\n" + curr.Text
				}
				continue
			}
		}

		mainText := curr.Text
		subText := ""

		if matches := bracketRegex.FindStringSubmatch(curr.Text); len(matches) > 2 {
			mainText = matches[1]
			subText = matches[2]
		} else if matches := delimiterRegex.FindStringSubmatch(curr.Text); len(matches) > 2 {
			mainText = matches[1]
			subText = matches[2]
		}

		lyrics = append(lyrics, LyricLine{
			Time:     curr.Time,
			MainText: mainText,
			SubText:  subText,
		})
	}

	return lyrics
}

func convertToUTF8(content []byte) string {
	detector := chardet.NewTextDetector()
	result, err := detector.DetectBest(content)
	if err != nil {
		return string(content)
	}

	switch result.Charset {
	case "GB-18030", "GBK":
		data, _, _ := transform.Bytes(simplifiedchinese.GBK.NewDecoder(), content)
		return string(data)
	case "Big5":
		data, _, _ := transform.Bytes(traditionalchinese.Big5.NewDecoder(), content)
		return string(data)
	case "Shift_JIS", "EUC-JP":
		data, _, _ := transform.Bytes(japanese.ShiftJIS.NewDecoder(), content)
		return string(data)
	default:
		return string(content)
	}
}
