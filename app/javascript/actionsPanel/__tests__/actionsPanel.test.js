/* eslint-disable no-restricted-globals */
import fetch from 'jest-fetch-mock';
import {
  addCloseListener,
  initializeHeight,
  addReactionButtonListeners,
  addAdjustTagListeners,
  addBottomActionsListeners,
 } from '../actionsPanel';

describe('addCloseListener()', () => {
  test('toggles the mod actions panel and its button on click', () => {
    document.body.innerHTML = `
    <body>
      <div class="mod-actions-menu showing">
        <button class="close-actions-panel circle centered-icon" type="button" title="Close moderator actions panel">
        </button>
      </div>
      <div id="mod-actions-menu-btn-area">
        <div class="mod-actions-menu-btn crayons-btn crayons-btn--icon-rounded crayons-btn--s hidden">
        </div>
      </div>
    </body>
    `;
    addCloseListener();

    const closeButton = document.querySelector('.close-actions-panel')
    closeButton.click();
    // eslint-disable-next-line no-restricted-globals
    const modPanel = top.document.querySelector('.mod-actions-menu')
    const modPanelBtn = top.document.querySelector('.mod-actions-menu-btn')
    expect(modPanel.classList).not.toContain('showing');
    expect(modPanelBtn.classList).not.toContain('hidden');
  })
})

describe('initializeHeight()', () => {
  test('it sets the height of the proper elements', () => {
    document.body.innerHTML = `
    <body>
      <div id="page-content">
        <div id="page-content-inner">
        </div>
      </div>
    </body>
    `;
    initializeHeight();

    const { body } = document
    expect(document.documentElement.style.height).toEqual('100%')
    expect(body.style.height).toEqual('100%')
    expect(body.style.margin).toEqual('0px')
    expect(body.style.marginTop).toEqual('0px')
    expect(body.style.marginBottom).toEqual('0px')
    expect(body.style.paddingTop).toEqual('0px')
    expect(body.style.paddingTop).toEqual('0px')
  })
})

describe('addReactionButtonListeners()', () => {
  beforeEach(() => {
    fetch.resetMocks();

    document.body.innerHTML = `
    <button class="reaction-button" data-reactable-id="1" data-reactable-type="Article" data-category="thumbsup">
    </button>
    <button class="reaction-button" data-reactable-id="1" data-reactable-type="Article" data-category="thumbsdown">
    </button>
    <button class="reaction-vomit-button" data-reactable-id="1" data-reactable-type="Article" data-category="vomit">
    </button>
    `

    const csrfToken = 'this-is-a-csrf-token';

    window.fetch = fetch;
    window.getCsrfToken = async () => csrfToken;
    top.addSnackbarItem = jest.fn()
  })

  function sampleResponse(category, create = true) {
    return JSON.stringify({
      outcome: {
        result: create ? 'create' : 'destroy',
        category,
      },
    });
  }

  describe('when no reactions are already reacted on', () => {
    test('it marks thumbs up reaction as reacted', async () => {
      let category = 'thumbsup';
      fetch.mockResponse(sampleResponse(category))
      addReactionButtonListeners();

      const thumbsupButton = document.querySelector(
        `.reaction-button[data-category="${category}"]`
      )
      thumbsupButton.click();
      expect(thumbsupButton.classList).toContain("reacted")

      category = 'thumbsdown';
      const thumbsdownButton = document.querySelector(
        `.reaction-button[data-category="${category}"]`,
      );
      thumbsdownButton.click();
      expect(thumbsdownButton.classList).toContain('reacted');

      category = 'vomit';
      fetch.resetMocks();
      fetch.mockResponse(sampleResponse(category));
      const vomitButton = document.querySelector(
        `.reaction-vomit-button[data-category="${category}"]`,
      );
      vomitButton.click();
      expect(vomitButton.classList).toContain('reacted');
    })
    test('it unmarks the proper reaction(s) when positive/negative reactions are clicked', async () => {
      let category = 'thumbsup';
      fetch.mockResponse(sampleResponse(category));
      addReactionButtonListeners();
      const thumbsupButton = document.querySelector(
        `.reaction-button[data-category="${category}"]`,
      );
      thumbsupButton.click();

      category = 'thumbsdown';
      fetch.resetMocks();
      fetch.mockResponse(sampleResponse(category));
      const thumbsdownButton = document.querySelector(
        `.reaction-button[data-category="${category}"]`,
      );
      thumbsdownButton.click();
      expect(thumbsupButton.classList).not.toContain('reacted');

      fetch.resetMocks();
      category = 'thumbsup';
      fetch.mockResponse(sampleResponse(category, false));
      thumbsupButton.click();
      expect(thumbsdownButton.classList).not.toContain('reacted');
      expect(thumbsupButton.classList).toContain('reacted');

      category = 'vomit';
      fetch.resetMocks();
      fetch.mockResponse(sampleResponse(category));
      const vomitButton = document.querySelector(
        `.reaction-vomit-button[data-category="${category}"]`,
      );
      vomitButton.click()
      expect(vomitButton.classList).toContain('reacted');
      expect(thumbsupButton.classList).not.toContain('reacted');
    })
  })
})

describe('addAdjustTagListeners()', () => {
  function sampleResponse(result = 'subtract') {
    return JSON.stringify({
      status: 'Success',
      result
    })
  }

  describe('when the user is tag moderator of #discuss', () => {
    describe('when an article is tagged with #discuss', () => {
      const tagName = 'discuss';
      beforeEach(() => {
        fetch.resetMocks();

        document.body.innerHTML = `
          <a href="/t/${tagName}" class="tag">${tagName}</a>
          <button class="adjustable-tag" data-adjustment-type="subtract" data-tag-name="${tagName}">
            #${tagName}
          </button>
          <form id="adjustment-reason-container" class="adjustment-reason-container hidden">
            <textarea class="crayons-textfield" placeholder="Reason for tag adjustment" id="tag-adjustment-reason" required></textarea>
            <button class="crayons-btn" id="tag-adjust-submit" type="submit">Submit</button>
          </form>
        `;

        const csrfToken = 'this-is-a-csrf-token';

        window.fetch = fetch;
        window.getCsrfToken = async () => csrfToken;
        top.addSnackbarItem = jest.fn();
        
      });
      // test('alert happens', () => {
      //   expect(window.alert).toHaveBeenCalled()
      // })
      test('it removes the tag from the panel and the article', async () => {
        fetch.mockResponse(sampleResponse());
        addAdjustTagListeners()
        
        const tagButton = document.querySelector('.adjustable-tag')
        tagButton.remove = jest.fn();
        const tagOnArticle = document.querySelector(
          `.tag[href="/t/${tagName}"]`,
        );
        tagOnArticle.remove = jest.fn();
        
        tagButton.click()
        // fill out form
        // click submit button
        document.querySelector('textarea').value = 'some reason'
        document.getElementById('tag-adjust-submit').click()
        expect(tagButton.remove).toHaveBeenCalled()
        expect(tagOnArticle.remove).toHaveBeenCalled()
        // expect(document.querySelector('.tag')).toBeNull()
        // expect(document.querySelector(`.tag[href="/t/${tagName}"]`)).toBeNull();
        
      })
    })
  })
})

// describe('toggleDropdown', () => {
//   beforeAll(() => {
//     document.body.innerHTML = `
//       <div class="other-things-container">
//         <div class="adjust-tags-options dropdown-options hidden"></div>
//         <div class="set-experience-options dropdown-options hidden"></div>
//       </div>
//     `;
//   })

//   describe('when type is set-experience', () => {
//     test('it toggles the experience options visibility', () => {
//       const setExpOptions = document.querySelector('.set-experience-options')
//       toggleDropdown('set-experience');
//       expect(setExpOptions.classList).not.toContain('hidden');
//       toggleDropdown('set-experience');
//       expect(setExpOptions.classList).toContain('hidden');
//     })
//   })
//   describe('when type is adjust-tags', () => {})
// })

/* eslint-enable no-restricted-globals */